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

  let body-label = label(
    "storyteller:annotation:body:" + kind + ":"
    + str(num)
  )

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
#let annotations-summary() = context {
  let annotations = annotations.final()

  for (kind, notes-and-labels) in annotations.pairs() {
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
  annotation("storyteller:note", body, note)
}
