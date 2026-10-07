<?php

namespace App\Providers;

use App\Services\Sms\LogSmsSender;
use App\Services\Sms\SmsSender;
use App\Services\Sms\WhatsAppSmsSender;
use App\Services\VideoProcessingService;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Binary locations are deployment-specific; the service itself should
        // not reach into config.
        $this->app->singleton(VideoProcessingService::class, function ($app) {
            return new VideoProcessingService(
                $app['config']->get('services.ffmpeg.binary', 'ffmpeg'),
                $app['config']->get('services.ffmpeg.probe_binary', 'ffprobe'),
            );
        });

        // Codes go to WhatsApp once credentials are configured; otherwise
        // they land in the log, which is what local dev runs without setup.
        $this->app->bind(SmsSender::class, function ($app) {
            $config = $app['config']->get('services.whatsapp');

            if (! empty($config['phone_number_id']) && ! empty($config['access_token'])) {
                return new WhatsAppSmsSender(
                    $config['phone_number_id'],
                    $config['access_token'],
                    $config['template_name'],
                    $config['template_language'],
                    $config['api_version'],
                );
            }

            return new LogSmsSender();
        });
    }

    public function boot(): void
    {
        //
    }
}
