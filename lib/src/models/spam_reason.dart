/// An explainable signal that contributed to a spam decision.
enum SpamReason {
  /// Too many messages arrived in one or more sliding windows.
  messageFlood,

  /// The same normalized message was sent repeatedly.
  duplicateMessages,

  /// Recent messages were nearly identical.
  similarMessages,

  /// The message contains too many links or is dominated by links.
  excessiveLinks,

  /// A recently used URL was repeated.
  repeatedLink,

  /// A character or emoji was repeated excessively.
  excessiveCharacters,

  /// Capitalization or punctuation is excessive.
  excessiveFormatting,

  /// A token or short phrase was repeated excessively.
  repeatedTokens,

  /// The sender is currently in a local temporary cooldown.
  senderSuspended,
}
