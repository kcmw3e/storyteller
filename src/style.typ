// This is the Storyteller styling module.
//
// These styles act somewhat like Typst `show`/`set` rules, but without the
// context nesting. Basically, once a style is set, it doesn't "unset" when the
// scope lightens.
//
// For an example of how to write a style for Storyteller, see `default-style`.
//
// Here is a usage example:
// ```typst
// #let intersting-style = new-style-from-default((
//   // Disable the default comparison block colors.
//   comparison-options = (text,),
// ))
//
// #current-style.update(interesting-style-style)
// ```
// -----------------------------------------------------------------------------
// This module is heavily inspired by the styling module in Resumania:
//   https://github.com/kcmw3e/resumania

// The default style. This should also be used as an example/template for
// writing custom styles.
#let default-style = (
  // These are styles applied to the entries in comparison blocks. They are
  // recycled if a comparison block has more entries than styles defined here.
  //
  // Each entry in the array is a function that takes some content and returns
  // some content. It must not be empty (if you want to disable the different
  // styling between comparisons, just set it to an array of one element that
  // contains the function `text`).
  comparison-options: (
    ..(blue, purple, green, eastern, olive, fuchsia, orange)
      .map(color => {
        (body) => text(fill: color, body)
      }),
  ),
  rework: (body) => text(fill: red, body),
  note: text,
)

// Create a new style using the default style as a basis for missing style
// parameters.
//
// The only parameter `style` is a dictionary formatted just like a full style
// (see `default-style` for an example), except it may be a *partial* style. The
// returned value will be a full style dictionary.
#let new-style-from-default(style) = {
  let new-style = default-style

  for (key, value) in style {
    new-style.insert(key, value)
  }

  return new-style
}

// The global style state, which may be updated freely so long as the new value
// contains all style parameters. It is encouraged to use
// `new-style-from-default` for this purpose to fill any missing parameters
// automatically.
#let current-style = state("storyteller:states:current-style", default-style)

// Reset the current style to the default style.
#let reset-style-to-default() = {
  current-style.update(default-style)
}
