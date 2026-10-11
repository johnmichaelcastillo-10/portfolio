<?php
/**
 * Title: Hero
 * Slug: jmc-portfolio/hero
 * Categories: jmc-portfolio
 * Description: Two columns: headline, summary and actions beside a tall photo with a stats card.
 *
 * The copy describes the owner as a developer in general; employers belong in Experience
 * only. The photo is CC0 (see assets/images/SOURCES.md), so it carries no credit. The stats
 * are resume facts only: change them when the resume changes.
 */

// Sized copies so phones don't download the 1026px original (made from it with GD at q80).
// Custom HTML rather than an Image block: core/image's saved markup has no srcset, so adding
// one would make the Site Editor flag the block as invalid.
$hero_src    = get_theme_file_uri( 'assets/images/hero-code.webp' );
$hero_srcset = sprintf(
	'%s 480w, %s 768w, %s 1026w',
	get_theme_file_uri( 'assets/images/hero-code-480.webp' ),
	get_theme_file_uri( 'assets/images/hero-code-768.webp' ),
	$hero_src
);
?>
<!-- wp:group {"tagName":"section","anchor":"top","align":"wide","className":"hero","layout":{"type":"default"}} -->
<section id="top" class="wp-block-group alignwide hero"><!-- wp:group {"className":"hero-copy","layout":{"type":"default"}} -->
<div class="wp-block-group hero-copy"><!-- wp:html -->
<p class="badge badge-outline hero-badge"><?php echo jmc_icon( 'map-pin' ); // phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped -- static SVG. ?>Software developer in Laguna, Philippines</p>
<!-- /wp:html -->

<!-- wp:heading {"level":1,"className":"hero-title"} -->
<h1 class="wp-block-heading hero-title">I build <span class="hl">web applications</span> and the APIs behind them.</h1>
<!-- /wp:heading -->

<!-- wp:paragraph {"className":"lead hero-lead"} -->
<p class="lead hero-lead">I'm John Michael, a software developer working in C#, ASP.NET and SQL Server, and building backend APIs in PHP with Laravel.</p>
<!-- /wp:paragraph -->

<!-- wp:buttons {"className":"hero-actions"} -->
<div class="wp-block-buttons hero-actions"><!-- wp:button {"className":"is-style-fill btn-arrow"} -->
<?php if ( jmc_has_projects() ) : ?>
<div class="wp-block-button is-style-fill btn-arrow"><a class="wp-block-button__link wp-element-button" href="#work">View my work</a></div>
<?php else : ?>
<div class="wp-block-button is-style-fill btn-arrow"><a class="wp-block-button__link wp-element-button" href="#contact">Get in touch</a></div>
<?php endif; ?>
<!-- /wp:button -->

<!-- wp:button {"className":"is-style-secondary","metadata":{"bindings":{"url":{"source":"jmc-portfolio/resume"}}}} -->
<div class="wp-block-button is-style-secondary"><a class="wp-block-button__link wp-element-button">Resume</a></div>
<!-- /wp:button -->

<!-- wp:button {"className":"is-style-text btn-external"} -->
<div class="wp-block-button is-style-text btn-external"><a class="wp-block-button__link wp-element-button" href="https://github.com/johnmichaelcastillo-10">GitHub</a></div>
<!-- /wp:button --></div>
<!-- /wp:buttons --></div>
<!-- /wp:group -->

<!-- wp:group {"className":"hero-media","layout":{"type":"default"}} -->
<div class="wp-block-group hero-media"><!-- wp:html -->
<figure class="wp-block-image size-full hero-figure"><img src="<?php echo esc_url( $hero_src ); ?>" srcset="<?php echo esc_attr( $hero_srcset ); ?>" sizes="(max-width: 640px) calc(100vw - 2rem), 470px" width="1026" height="1282" alt="Close-up of colourful PHP code in a code editor" style="aspect-ratio:4/5;object-fit:cover"/></figure>
<!-- /wp:html -->

<!-- wp:html -->
<dl class="stats-card">
	<div><dt>Experience</dt><dd>Nearly 2 years</dd></div>
	<div><dt>Roles</dt><dd>Intern to junior programmer</dd></div>
	<div><dt>Stack</dt><dd>C#, SQL Server, PHP</dd></div>
</dl>
<!-- /wp:html --></div>
<!-- /wp:group --></section>
<!-- /wp:group -->
