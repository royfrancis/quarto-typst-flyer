#show: nbis-flyer.with(
  $if(subtitle)$
    subtitle: [$subtitle$],
  $endif$

  $if(title)$
    title: [$title$],
  $endif$

  $if(description)$
    description: [$description$],
  $endif$

  $if(content)$
    content: [$content$],
  $endif$

  $if(date-range)$
    date-range: [$date-range$],
  $endif$

  $if(location)$
    location: [$location$],
  $endif$

  $if(info)$
    info: [$info$],
  $endif$

  $if(deadline)$
    deadline: [$deadline$],
  $endif$

  $if(bg-image)$
    bg-image: (
      path: "$bg-image.path$"
    ), 
  $endif$

  $if(logo-image)$
    logo-image: (
      path: "$logo-image.path$"
    ), 
  $endif$

  $if(logo-height)$
    logo-height: $logo-height$,
  $endif$

  $if(banner-image)$
    banner-image: (
      path: "$banner-image.path$"
    ), 
  $endif$

  $if(banner-height)$
    banner-height: $banner-height$,
  $endif$

  $if(footer-left)$
    footer-left: [$footer-left$],
  $endif$

  $if(footer-right)$
    footer-right: [$footer-right$],
  $endif$

  $if(font-size)$
    font-size: $font-size$,
  $endif$

  $if(color-text)$
    color-text: "$color-text$",
  $endif$

  $if(color-info)$
    color-info: "$color-info$",
  $endif$
)
