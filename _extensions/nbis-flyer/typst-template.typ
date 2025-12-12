#let default-color-text = rgb("#1D293D")
#let default-color-info = rgb("#E9F2D1")

#let default-font-size = 13pt

#set text(font: "Lato", fill: default-color-text, size: default-font-size)
#set par(leading: 0.7em)
#set block(spacing: 1.2em)

// A helper to sanitize text values by escaping special characters
#let sanitize-text(value) = if type(value) == str {
  value.replace("@", "\\@")
} else {
  value
}
#let sanitize(value) = if value == none { [] } else { sanitize-text(value) }

// Accepts a color literal (color) or string (e.g., "#1D293D") and returns a usable color
#let parse-color(value, fallback) = {
  if value == none {
    return fallback
  }
  if type(value) == color {
    return value
  }
  if type(value) == str {
    let cleaned = value.replace("\\#", "#").trim()
    if cleaned.starts-with("#") {
      return rgb(cleaned)
    }
  }
  fallback
}

// A helper to layout an image that overflows its container while preserving aspect ratio
#let overflowing-image(img) = layout(container => {
  let dim = measure(img)
  let container-ratio = container.width / container.height
  let img-ratio = dim.width / dim.height

  if img-ratio > container-ratio {
    // the image will have horizontal overflow; set the width according to the aspect ratio
    set image(height: 100%, width: container.height * img-ratio)
    img
  } else {
    // the image will have vertical overflow; set the height according to the aspect ratio
    set image(width: 100%, height: container.width / img-ratio)
    img
  }
})

#let nbis-flyer(
  subtitle: none,
  title: none,
  description: none,
  content: none,
  date-range: none,
  location: none,
  info: none,
  deadline: none,
  bg-image: none,
  logo-image: none,
  logo-height: 1cm,
  banner-image: none,
  banner-height: 5cm,
  content-side-padding: 2.15cm,
  content-top-padding: 2.5cm,
  content-bottom-padding: 2.5cm,
  font-size: default-font-size,
  color-text: default-color-text,
  color-info: default-color-info,
  footer-left: none,
  footer-right: none,
  body,
) = {
  let font-base = font-size
  let font-h1 = font-base * 1.802
  let font-h2 = font-base * 1.602
  let font-h3 = font-base * 1.424
  let font-h4 = font-base * 1.266
  let font-h5 = font-base * 1.125
  let font-h6 = font-base

  let font-hero-title = font-h1 * 1.2
  let font-hero-subtitle = font-h3
  let font-hero-description = font-h5
  let font-chip-label = font-h6 * 0.78
  let font-chip-value = font-h5
  let font-footer = font-h6

  let palette-text = parse-color(color-text, default-color-text)
  let palette-info = parse-color(color-info, default-color-info)

  set text(font: "Lato", fill: palette-text, size: font-base)

  let background-container = {
    if bg-image == none {
      none
    } else {
      image(bg-image.path, width: 100%, height: 100%, fit: "cover")
    }
  }

  let banner-container = if banner-image == none {
    none
  } else {
    show: pad.with(x: -content-side-padding, y: -content-top-padding)
    show: block.with(
      height: banner-height,
      width: 100%,
      clip: true,
    )
    // show: move.with(dx: 1cm)
    set align(right)
    overflowing-image(image(banner-image.path))
  }

  let logo = if logo-image == none {
    none
  } else {
    place(top, block(
      width: 100%,
      inset: content-side-padding,
      height: banner-height,
      place(
        horizon + left,
        image(logo-image.path, height: logo-height),
      ),
    ))
  }

  let footer-container = if footer-left == none and footer-right == none {
    []
  } else {
    box(
      width: 100%,
      pad(top: 6pt, grid(
        columns: (1fr, 1fr),
        column-gutter: 12pt,
        align(left + bottom, text(size: font-footer, fill: palette-text, sanitize-text(footer-left))),
        align(right + bottom, text(size: font-footer, fill: palette-text, sanitize-text(footer-right))),
      )),
    )
  }

  set page(
    paper: "a4",
    margin: (
      left: content-side-padding,
      right: content-side-padding,
      top: content-top-padding,
      bottom: content-bottom-padding,
    ),
    background: background-container,
    foreground: logo,
    footer: footer-container,
  )

  show link: underline
  show heading.where(level: 1): set text(size: font-h1, weight: 700, fill: palette-text)
  show heading.where(level: 2): set text(size: font-h2, weight: 600, fill: palette-text)
  show heading.where(level: 3): set text(size: font-h3, weight: 600, fill: palette-text)
  show heading.where(level: 4): set text(size: font-h4, weight: 600, fill: palette-text)
  show heading.where(level: 5): set text(size: font-h5, weight: 600, fill: palette-text)
  show heading.where(level: 6): set text(size: font-h6, weight: 600, fill: palette-text)
  show heading: it => {
    set block(below: 0.5em)
    it
  }

  let info-chip = (label, value) => {
    if value == none {
      return []
    }
    block(
      width: 100%,
      fill: palette-info,
      radius: 4pt,
      inset: 15pt,
      grid(
        columns: 1fr,
        row-gutter: 8pt,
        text(size: font-chip-label, weight: 800, tracking: 0.1em, fill: palette-text, label),
        text(size: font-chip-value, fill: palette-text, value)
      ),
    )
  }

  let info-grid = if (date-range == none) and (location == none) and (info == none) and (deadline == none) {
    []
  } else {
    grid(
      columns: (1fr, 1fr),
      column-gutter: 8pt,
      row-gutter: 8pt,
      info-chip("DATE", sanitize(date-range)), info-chip("LOCATION", sanitize(location)),
      info-chip("INFO", sanitize(info)), info-chip("DEADLINE", sanitize(deadline)),
    )
  }

  let general-container = block(
    width: 100%,
    pad(
      top: (banner-height - content-top-padding) + 0.5cm,
      grid(
        columns: 1fr,
        row-gutter: 18pt,
        if subtitle == none { [] } else {
          text(size: font-hero-subtitle, weight: 600, tracking: 0.12em, fill: palette-text, sanitize(subtitle))
        },
        if title == none { [] } else {
          pad(
            bottom: 5pt,
            text(size: font-hero-title, weight: 600, fill: palette-text, sanitize(title)),
          )
        },
        if description == none { [] } else {
          pad(
            bottom: 5pt,
            text(size: font-hero-description, fill: palette-text, sanitize(description)),
          )
        },
        pad(
          bottom: 5pt,
          info-grid,
        ),
        if content == none { [] } else {
          pad(
            bottom: 5pt,
            text(size: font-base, fill: palette-text, sanitize(content)),
          )
        },
        body
      ),
    ),
  )

  grid(
    columns: 1fr,
    rows: (auto, 1fr, auto),
    row-gutter: 24pt,
    banner-container,
    general-container
  )
}
