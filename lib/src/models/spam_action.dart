/// The action recommended to the receiving application.
enum SpamAction {
  /// Accept and normally display the message.
  allow,

  /// Hide or discard this message locally.
  filter,

  /// Reject this sender locally until its temporary cooldown expires.
  suspend,
}
