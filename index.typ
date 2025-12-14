// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}

#let default-color-text = rgb("#1D293D")
#let default-color-code = rgb("#E4E4E7")
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
        align(left + bottom, text(size: font-footer, fill: palette-text, sanitize(footer-left))),
        align(right + bottom, text(size: font-footer, fill: palette-text, sanitize(footer-right))),
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

  // Inline code styling (Pandoc emits inline code as raw, non-block elements)
  let inline-code = body => box(
    fill: rgb(default-color-code),
    inset: (x: 4pt, y: 4pt),
    baseline: 4pt,
    radius: 3pt,
    stroke: none,
    body,
  )

  show raw.where(block: false): it => inline-code(it)

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

#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
)

#show: nbis-flyer.with(
      subtitle: [NBIS • TRAINING],
  
      title: [Workshop On Data Analysis],
  
      description: [Join us for an in-depth workshop on data analysis techniques and tools. \
This workshop is designed for researchers and professionals looking to enhance their data analysis skills.

],
  
      content: [=== Workshop Overview
<workshop-overview>
This workshop will cover various data analysis methods, including statistical analysis, data visualization, and machine learning techniques. Participants will have hands-on sessions to apply the concepts learned.

=== Who Should Attend?
<who-should-attend>
This workshop is ideal for researchers, data scientists, and professionals in related fields who want to improve their data analysis capabilities.

],
  
      date-range: [10-15 June 2026],
  
      location: [Uppsala, Sweden],
  
      info: [www.website.com/workshop],
  
      deadline: [03 May 2026],
  
      bg-image: (
      path: "assets/background.png"
    ), 
  
      logo-image: (
      path: "assets/logo.png"
    ), 
  
      logo-height: 1cm,
  
      banner-image: (
      path: "assets/banner.png"
    ), 
  
      banner-height: 5cm,
  
      footer-left: [2026 • NBIS],
  
      footer-right: [education\@nbis.se],
  
      font-size: 13pt,
  
      color-text: "\#1D293D",
  
      color-info: "\#E9F2D1",
  )






