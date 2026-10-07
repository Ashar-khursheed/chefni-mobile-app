<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

/**
 * Boots the Laravel application for feature tests. Extending PHPUnit's
 * TestCase directly skips the container, so anything using app() or the
 * database silently fails.
 */
abstract class TestCase extends BaseTestCase
{
    use CreatesApplication;
}
