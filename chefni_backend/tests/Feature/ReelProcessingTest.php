<?php

namespace Tests\Feature;

use App\Services\VideoProcessingService;
use RuntimeException;
use Tests\TestCase;

/**
 * Encoding needs a real ffmpeg and a real video, so the cases that can be
 * asserted without either are the contract around it: what the service refuses,
 * and the shape callers depend on.
 */
class ReelProcessingTest extends TestCase
{
    private function service(): VideoProcessingService
    {
        return app(VideoProcessingService::class);
    }

    public function test_a_missing_source_file_is_refused_before_any_encoding(): void
    {
        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('Source video not found');

        $this->service()->processAndCompressReel(
            storage_path('app/does-not-exist.mp4'),
            storage_path('app/tmp/out.mp4'),
            storage_path('app/watermark.png'),
        );
    }

    public function test_thumbnail_extraction_reports_failure_rather_than_throwing(): void
    {
        // The dashboard tolerates a missing thumbnail, so this path returns
        // false instead of failing the whole job.
        $result = $this->service()->extractThumbnail(
            storage_path('app/does-not-exist.mp4'),
            storage_path('app/tmp/thumb.jpg'),
        );

        $this->assertFalse($result);
    }

    public function test_availability_reflects_whether_ffmpeg_is_installed(): void
    {
        // The upload endpoint refuses with a 503 when this is false, so the
        // check must answer without throwing on a host that lacks ffmpeg.
        $this->assertIsBool($this->service()->isAvailable());
    }
}
