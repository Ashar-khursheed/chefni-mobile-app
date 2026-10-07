<?php

namespace App\Services;

use RuntimeException;
use Symfony\Component\Process\Exception\ProcessTimedOutException;
use Symfony\Component\Process\Process;

/**
 * FFmpeg-backed reel production: trims to a 60-second maximum, fills a 9:16
 * 1080x1920 frame, overlays the Chefni watermark and writes a fast-start MP4.
 *
 * Every failure here is reported as an exception. A reel that did not encode
 * must not be presented to the user as one that did.
 */
class VideoProcessingService
{
    private const MAX_DURATION_SECONDS = 60;
    private const OUTPUT_WIDTH = 1080;
    private const OUTPUT_HEIGHT = 1920;
    private const TARGET_CRF = 23;
    private const AUDIO_BITRATE = '128k';

    /** Encoding a minute of video is slow; give it room but never hang forever. */
    private const ENCODE_TIMEOUT_SECONDS = 600;
    private const PROBE_TIMEOUT_SECONDS = 30;

    public function __construct(
        private readonly string $ffmpegBinary = 'ffmpeg',
        private readonly string $ffprobeBinary = 'ffprobe',
    ) {
    }

    /**
     * True when both binaries respond, so callers can fail fast with a clear
     * message instead of surfacing a cryptic encoder error later.
     */
    public function isAvailable(): bool
    {
        foreach ([$this->ffmpegBinary, $this->ffprobeBinary] as $binary) {
            $process = new Process([$binary, '-version']);
            $process->setTimeout(10);

            try {
                $process->run();
            } catch (\Throwable) {
                return false;
            }

            if (! $process->isSuccessful()) {
                return false;
            }
        }

        return true;
    }

    /**
     * Compress a raw upload into a watermarked 1-minute reel.
     *
     * @param  string  $watermarkPath  Chefni logo PNG; when missing the encode
     *                                 still runs, just without the overlay.
     * @return array{original_duration_sec: float, reel_duration_sec: float, file_size_bytes: int, resolution: string, watermark_applied: bool}
     *
     * @throws RuntimeException when the encode fails or produces no output.
     */
    public function processAndCompressReel(
        string $inputFilePath,
        string $outputFilePath,
        string $watermarkPath,
        float $startTimeCut = 0.0,
    ): array {
        if (! is_file($inputFilePath)) {
            throw new RuntimeException("Source video not found at: {$inputFilePath}");
        }

        $outputDir = dirname($outputFilePath);
        if (! is_dir($outputDir) && ! mkdir($outputDir, 0755, true) && ! is_dir($outputDir)) {
            throw new RuntimeException("Could not create output directory: {$outputDir}");
        }

        $sourceDuration = $this->probeDuration($inputFilePath);
        $remaining = $sourceDuration - $startTimeCut;

        if ($remaining < 1.0) {
            throw new RuntimeException(
                'The video is shorter than one second after the requested trim point.'
            );
        }

        $reelDuration = min(self::MAX_DURATION_SECONDS, $remaining);
        $hasWatermark = is_file($watermarkPath);

        $process = new Process(
            $this->buildEncodeCommand(
                $inputFilePath,
                $outputFilePath,
                $watermarkPath,
                $startTimeCut,
                $reelDuration,
                $hasWatermark,
            )
        );
        $process->setTimeout(self::ENCODE_TIMEOUT_SECONDS);

        try {
            $process->run();
        } catch (ProcessTimedOutException) {
            @unlink($outputFilePath);
            throw new RuntimeException(
                'Video encoding timed out after '.self::ENCODE_TIMEOUT_SECONDS.' seconds.'
            );
        }

        if (! $process->isSuccessful()) {
            @unlink($outputFilePath);
            throw new RuntimeException(
                'FFmpeg could not encode this video: '.$this->lastMeaningfulLine($process->getErrorOutput())
            );
        }

        if (! is_file($outputFilePath) || filesize($outputFilePath) === 0) {
            throw new RuntimeException('FFmpeg reported success but produced no output file.');
        }

        return [
            'original_duration_sec' => round($sourceDuration, 2),
            'reel_duration_sec' => round($reelDuration, 2),
            'file_size_bytes' => filesize($outputFilePath),
            'resolution' => self::OUTPUT_WIDTH.'x'.self::OUTPUT_HEIGHT,
            'watermark_applied' => $hasWatermark,
        ];
    }

    /**
     * Grab a single frame for the dashboard thumbnail. Returns false rather
     * than throwing: a missing thumbnail should not fail an otherwise good reel.
     */
    public function extractThumbnail(string $videoPath, string $outputPath, float $atSecond = 1.0): bool
    {
        $outputDir = dirname($outputPath);
        if (! is_dir($outputDir) && ! mkdir($outputDir, 0755, true) && ! is_dir($outputDir)) {
            return false;
        }

        $process = new Process([
            $this->ffmpegBinary, '-y',
            '-ss', (string) $atSecond,
            '-i', $videoPath,
            '-frames:v', '1',
            '-vf', 'scale=540:-1',
            '-q:v', '3',
            $outputPath,
        ]);
        $process->setTimeout(self::PROBE_TIMEOUT_SECONDS);

        try {
            $process->run();
        } catch (\Throwable) {
            return false;
        }

        return $process->isSuccessful() && is_file($outputPath) && filesize($outputPath) > 0;
    }

    /**
     * Pull a mono 16 kHz WAV track for speech-to-text. Returns false when the
     * video carries no audio, which the caller treats as "nothing to transcribe".
     */
    public function extractAudioForTranscription(string $videoPath, string $outputPath): bool
    {
        if (! $this->hasAudioStream($videoPath)) {
            return false;
        }

        $outputDir = dirname($outputPath);
        if (! is_dir($outputDir) && ! mkdir($outputDir, 0755, true) && ! is_dir($outputDir)) {
            return false;
        }

        $process = new Process([
            $this->ffmpegBinary, '-y',
            '-i', $videoPath,
            '-vn',
            '-ac', '1',
            '-ar', '16000',
            '-c:a', 'pcm_s16le',
            $outputPath,
        ]);
        $process->setTimeout(self::ENCODE_TIMEOUT_SECONDS);

        try {
            $process->run();
        } catch (\Throwable) {
            return false;
        }

        return $process->isSuccessful() && is_file($outputPath) && filesize($outputPath) > 0;
    }

    public function hasAudioStream(string $videoPath): bool
    {
        $process = new Process([
            $this->ffprobeBinary,
            '-v', 'error',
            '-select_streams', 'a:0',
            '-show_entries', 'stream=codec_type',
            '-of', 'csv=p=0',
            $videoPath,
        ]);
        $process->setTimeout(self::PROBE_TIMEOUT_SECONDS);

        try {
            $process->run();
        } catch (\Throwable) {
            return false;
        }

        return $process->isSuccessful() && str_contains($process->getOutput(), 'audio');
    }

    /**
     * @throws RuntimeException when ffprobe cannot read a duration, which means
     *                          the file is not decodable video.
     */
    public function probeDuration(string $filePath): float
    {
        $process = new Process([
            $this->ffprobeBinary,
            '-v', 'error',
            '-show_entries', 'format=duration',
            '-of', 'default=noprint_wrappers=1:nokey=1',
            $filePath,
        ]);
        $process->setTimeout(self::PROBE_TIMEOUT_SECONDS);

        try {
            $process->run();
        } catch (\Throwable $e) {
            throw new RuntimeException('Could not read the video: '.$e->getMessage(), 0, $e);
        }

        $output = trim($process->getOutput());

        if (! $process->isSuccessful() || ! is_numeric($output)) {
            throw new RuntimeException(
                'This file does not appear to be a readable video: '
                .$this->lastMeaningfulLine($process->getErrorOutput())
            );
        }

        return (float) $output;
    }

    /**
     * Scale-and-crop fills the 9:16 frame without letterboxing, then the
     * watermark sits in the top-right corner clear of platform UI overlays.
     *
     * @return list<string>
     */
    private function buildEncodeCommand(
        string $input,
        string $output,
        string $watermark,
        float $startTime,
        float $duration,
        bool $hasWatermark,
    ): array {
        $scaleChain = sprintf(
            '[0:v]scale=%d:%d:force_original_aspect_ratio=increase,crop=%d:%d,setsar=1',
            self::OUTPUT_WIDTH,
            self::OUTPUT_HEIGHT,
            self::OUTPUT_WIDTH,
            self::OUTPUT_HEIGHT,
        );

        $command = [
            $this->ffmpegBinary, '-y',
            // Seeking before -i is the fast path; -t then limits the reel length.
            '-ss', (string) $startTime,
            '-t', (string) $duration,
            '-i', $input,
        ];

        if ($hasWatermark) {
            $command[] = '-i';
            $command[] = $watermark;
            $filter = $scaleChain.'[scaled];[1:v]scale=180:-1[wm];[scaled][wm]overlay=W-w-30:40[outv]';
        } else {
            $filter = $scaleChain.'[outv]';
        }

        return array_merge($command, [
            '-filter_complex', $filter,
            '-map', '[outv]',
            // Sources without audio would abort the map without the `?`.
            '-map', '0:a?',
            '-c:v', 'libx264',
            '-preset', 'medium',
            '-crf', (string) self::TARGET_CRF,
            '-pix_fmt', 'yuv420p',
            '-c:a', 'aac',
            '-b:a', self::AUDIO_BITRATE,
            '-movflags', '+faststart',
            $output,
        ]);
    }

    /** FFmpeg's real complaint is on the last non-empty line of stderr. */
    private function lastMeaningfulLine(string $stderr): string
    {
        $lines = array_values(array_filter(array_map('trim', explode("\n", $stderr))));

        return $lines === [] ? 'no error output' : end($lines);
    }
}
