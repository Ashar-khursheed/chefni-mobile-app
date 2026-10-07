<?php

namespace App\Exceptions;

use RuntimeException;

/**
 * The OTP could not be handed off to the delivery channel (WhatsApp API
 * down, bad credentials, number not reachable). Distinct from the cooldown
 * RuntimeException in OtpService so the controller can tell "try again
 * shortly" apart from "the service itself is broken right now".
 */
class OtpDeliveryException extends RuntimeException
{
}
