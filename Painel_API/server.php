<?php

/**
 * Laravel - A PHP Framework For Web Artisans
 *
 * @package  Laravel
 * @author   Taylor Otwell <taylor@laravel.com>
 */

$uri = urldecode(
    parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH)
);

// This file allows us to emulate Apache's "mod_rewrite" functionality from the
// built-in PHP web server. This provides a convenient way to test a Laravel
// application without having installed a "real" web server software here.
if ($uri !== '/' && file_exists(__DIR__.'/public'.$uri)) {
    return false;
}

// Handle asset paths that include 'public/' prefix (used by Blade templates)
if (strpos($uri, '/public/') === 0) {
    $realPath = __DIR__.'/public/'.substr($uri, 8);
    if (file_exists($realPath)) {
        $mime = mime_content_type($realPath);
        $ext = pathinfo($realPath, PATHINFO_EXTENSION);
        $mimeMap = ['css' => 'text/css', 'js' => 'application/javascript', 'svg' => 'image/svg+xml', 'png' => 'image/png', 'jpg' => 'image/jpeg', 'gif' => 'image/gif', 'mp3' => 'audio/mpeg', 'woff' => 'font/woff', 'woff2' => 'font/woff2', 'ttf' => 'font/ttf'];
        header('Content-Type: ' . ($mimeMap[$ext] ?? $mime));
        readfile($realPath);
        return true;
    }
}

require_once __DIR__.'/public/index.php';
