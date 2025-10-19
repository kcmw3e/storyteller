// These are annotations for a story.
//
// Annotations in Storyteller are metadata that doesn't end up in the final
// product, but may be helpful during story development and editing.
//
// Some annotations are "strict". This means that they cannot be included in a
// print-ready version of the story. In other words, Storyteller will force a
// Typst panic if an attempt is made to compile the print-ready version of the
// story while they are still included in the document.
// -----------------------------------------------------------------------------

#import "@preview/oxifmt:1.0.0": strfmt

#import "style.typ": current-style

// This state tracks all annotations that are added to the document. They can be
// used to produce an "annotation summary" (even at the beginning of the
// document!), which lists all of the annotations for reach kind with links to
// their locations in the document. See `annotations-summary` for more details.
//
// The state tracks a dictionary mapping an annotation kind to an array of
// annotation entries. Annotation entries are arrays of the annotation's note
// and its label, which can be used to create a reference/link.
#let annotations = state("storyteller:annotations", (:))

// Attach an annotation to some block of content. The annotation currently can
// only go in the footnotes.
#let annotation(kind, body, note) = context {
  // This makes sure every label is unique for each annotation of each kind.
  let num = annotations.get().at(kind, default: ()).len()

  let body-label = label(strfmt("storyteller:annotation:body:{}-{}", kind, num))

  annotations.update(old => {
    if kind not in old {
      old.insert(kind, ())
    }
    old.at(kind).push((note, body-label))

    old
  })

  [#body #body-label]
  footnote(note)
}

// Create a summary of all the annotations in the document. It can be placed
// anywhere in the document, and produces a list of each annotation under its
// kind.
//
// A word of caution: if any annotaion notes have `label`s in them, the document
// will fail to compile since it cannot have duplicate labels (since this
// function duplicates the `note` part of annotations).
//
// The `filter` argument can be used to specify a filter for what to show in the
// summary. If it is `none`, then all annotations will be shown. It also may be:
//   - a function that takes the annotation `kind` as input and returns `true`
//     if the kind should be included and `false` if not
//   - a string which will cause only an exact match of annotation `kind`s to be
//     shown
//   - a `regex`, where any matching annotation `kind` to the regular expression
//     will be included
#let annotations-summary(filter: none) = context {
  let annotations = annotations.final()

  let filter = if filter == none {
    (key) => true
  } else if type(filter) == function {
    filter
  } else if type(filter) == str {
    (key) => key == kind
  } else if type(filter) == regex {
    (key) => filter in key
  } else {
    panic(strfmt("Cannot filter on annotations with '{}'.", kind))
  }

  let kinds = annotations.keys().filter(filter)

  for kind in kinds {
    let notes-and-labels = annotations.at(kind)
    let notes = notes-and-labels.map(note-and-label => {
      let (note, label) = note-and-label
      link(label, note)
    })
    [#kind: #list(..notes)]
  }
}

// Add a note to some text. This is currently just a shorthand for adding a
// footnote, with the added benefit that it can be shown in the annotations
// summary.
#let note(body, note) = {
  let body = context {
    let styler = current-style.get().note
    styler(body)
  }
  annotation("storyteller:note", body, note)
}

// Tracks the number of rework-marked sections in the document. Used for
// checking outstanding changes needed before compiling a production-ready
// document.
#let num-reworks = state("storyteller:reworks", 0)

// Annotate a section to be reworked.
//
// The number of outstanding sections marked for reworking is tracked in
// `num-reworks`, and `check-reworks` can be used to cause Typst to panic if
// this number is nonzero. Storyteller uses this behavior for disallowing the
// compilation of a document in "print-ready" format while it still has parts
// marked for rework.
#let rework(body, note) = {
  num-reworks.update(old => old + 1)

  let body = context {
    let styler = current-style.get().rework
    styler(body)
  }
  annotation("storyteller:rework", body, note)
}

// Check if there are any outstanding sections marked for reworking. Panic if
// there are any.
//
// A call to this can be placed anywhere in the document since it uses the final
// value of the `num-reworks` state.
#let check-reworks() = context {
  let num-reworks = num-reworks.final()
  if num-reworks > 0 {
    panic(strfmt("Pending reworks: {}", num-reworks))
  }
}

// Output multiple versions of the same section next to each other, optionally
// with a note.
//
// The `dir` parameter determines which direction to order the comparison
// entries (may be any of the built-in Typst directions `ltr`, `rtl`, `ttb`,
// or `btt`), and `inline` determines whether to `box` the output or not.
#let comparison(note: [Comparison], dir: ltr, inline: false, ..bodies) = {
  let bodies = bodies.pos()

  if dir in (rtl, btt) {
    bodies = bodies.rev()
  }

  let bodies = (bodies
    .enumerate()
    .map(i-and-body => context {
      let (i, body) = i-and-body
      let option-styles = current-style.get().comparison-options
      let style-index = calc.rem(i, option-styles.len())
      let styler = option-styles.at(style-index)
      styler(body)
    })
  )

  let body = if dir.axis() == "horizontal" {
    grid(columns: bodies.len(), gutter: 1em, ..bodies)
  } else if dir.axis() == "vertical" {
    set par.line(numbering: none)
    grid(rows: bodies.len(), gutter: 1em, ..bodies)
  } else {
    panic(strfmt("Invalid direction '{}'.", dir))
  }

  body = if inline {
    box(body)
  } else {
    body
  }

  annotation("storyteller:comparison", body, note)
}
