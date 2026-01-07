extension String {
  func indentedBy(_ indentation: String) -> String {
    split(separator: "\n").joined(separator: "\n" + indentation)
  }
}
