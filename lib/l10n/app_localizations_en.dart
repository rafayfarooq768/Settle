// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Settle';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get signInEmailLabel => 'Email';

  @override
  String get signInPasswordLabel => 'Password';

  @override
  String get signInButton => 'Sign in';

  @override
  String get signUpPrompt => 'New here?';

  @override
  String get signUpButton => 'Create account';

  @override
  String get signUpTitle => 'Create account';

  @override
  String get signUpNameLabel => 'Your name';

  @override
  String get signUpNameHelper => 'Friends see this name in groups.';

  @override
  String get signInPrompt => 'Already have an account?';

  @override
  String get orDivider => 'or';

  @override
  String get forgotPasswordButton => 'Forgot password?';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordInstructions =>
      'Enter your account email. We\'ll send you a link to choose a new password.';

  @override
  String get resetPasswordButton => 'Send reset link';

  @override
  String get resetPasswordCheckEmailTitle => 'Check your email';

  @override
  String resetPasswordCheckEmailBody(String email) {
    return 'If an account uses $email, a reset link is on its way. Open it, choose a new password, then come back and sign in.';
  }

  @override
  String get resetPasswordSpamHint =>
      'Not there after a few minutes? Check your spam folder.';

  @override
  String get resetPasswordResend => 'Send again';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get errorNameRequired => 'Enter your name.';

  @override
  String get errorInvalidEmail => 'Enter a valid email address.';

  @override
  String get errorPasswordRequired => 'Enter your password.';

  @override
  String get errorWeakPassword => 'Password must be at least 6 characters.';

  @override
  String get errorWrongPassword => 'Incorrect email or password.';

  @override
  String get errorUserNotFound => 'No account found with this email.';

  @override
  String get errorEmailInUse => 'An account already exists with this email.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'No internet connection. Please try again.';

  @override
  String homeGreeting(String name) {
    return 'Salam, $name';
  }

  @override
  String get signOutButton => 'Sign out';

  @override
  String get homeNoGroups => 'No groups yet. Create one or join with a code.';

  @override
  String get createGroupButton => 'Create group';

  @override
  String get joinWithCodeButton => 'Join with a code';

  @override
  String get moreOptions => 'More options';

  @override
  String get createGroupTitle => 'New group';

  @override
  String get groupNameLabel => 'Group name';

  @override
  String get groupTypeLabel => 'Type (optional)';

  @override
  String get groupTypeHelper => 'For example Trip or Home.';

  @override
  String get groupTypeFriends => 'Friends';

  @override
  String get groupTypeTrip => 'Trip';

  @override
  String get groupTypeHome => 'Home';

  @override
  String get groupTypeOffice => 'Office';

  @override
  String get groupTypeFamily => 'Family';

  @override
  String get errorGroupNameRequired => 'Enter a group name.';

  @override
  String get groupCreated => 'Done! Group ban gaya';

  @override
  String get groupSettingsTooltip => 'Group settings';

  @override
  String get groupOnlyYou => 'Add your friends to start splitting.';

  @override
  String get groupNoExpenses => 'Abhi koi expense nahi.';

  @override
  String get inviteFriendsButton => 'Invite friends';

  @override
  String get addByNameButton => 'Add by name';

  @override
  String get groupSettingsTitle => 'Group settings';

  @override
  String get sectionGroup => 'Group';

  @override
  String sectionMembers(int count) {
    return 'Members ($count)';
  }

  @override
  String get sectionInvite => 'Invite';

  @override
  String joinCodeRow(String code) {
    return 'Join code $code';
  }

  @override
  String memberYou(String name) {
    return '$name (you)';
  }

  @override
  String get memberNotJoined => 'not joined yet';

  @override
  String get memberLeft => 'left the group';

  @override
  String get editGroupTitle => 'Edit group';

  @override
  String get saveButton => 'Save';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get addPlaceholderTitle => 'Add by name';

  @override
  String get addPlaceholderHelper => 'They can claim this name when they join.';

  @override
  String get renamePlaceholderTitle => 'Change name';

  @override
  String get memberNameLabel => 'Name';

  @override
  String get addButton => 'Add';

  @override
  String placeholderAdded(String name) {
    return '$name added';
  }

  @override
  String get leaveGroupButton => 'Leave group';

  @override
  String leaveGroupDialogTitle(String group) {
    return 'Leave $group?';
  }

  @override
  String get leaveGroupDialogBody =>
      'You won\'t see this group any more. You can join again with its code.';

  @override
  String get leaveGroupConfirm => 'Leave';

  @override
  String leaveGroupNotSettled(String amount) {
    return 'Settle up first. Your balance here is $amount.';
  }

  @override
  String get inviteTitle => 'Invite friends';

  @override
  String get inviteInstructions =>
      'Friends install Settle, tap Join with a code, and enter this code or scan the QR.';

  @override
  String inviteQrLabel(String code) {
    return 'QR code for $code';
  }

  @override
  String get shareOnWhatsApp => 'Share on WhatsApp';

  @override
  String get copyCodeButton => 'Copy code';

  @override
  String get codeCopied => 'Code copied';

  @override
  String inviteMessage(String code, String link) {
    return 'Join our group on Settle. Code: $code. Download: $link';
  }

  @override
  String get newCodeButton => 'Get a new code';

  @override
  String get newCodeDialogTitle => 'Get a new join code?';

  @override
  String newCodeDialogBody(String code) {
    return 'The code $code will stop working. People already in the group stay in it.';
  }

  @override
  String get newCodeConfirm => 'Get new code';

  @override
  String get errorOpenWhatsApp => 'Couldn\'t open WhatsApp.';

  @override
  String get joinTitle => 'Join a group';

  @override
  String get joinCodeLabel => 'Join code';

  @override
  String get joinCodeHint => 'CHAI-7KQ2M';

  @override
  String get scanQrButton => 'Scan QR';

  @override
  String get joinButton => 'Join';

  @override
  String get errorCodeFormat => 'Codes look like CHAI-7KQ2M.';

  @override
  String get errorCodeNotFound =>
      'No group has this code. It may have been changed.';

  @override
  String get scanTitle => 'Scan QR';

  @override
  String get scanHint => 'Point the camera at the group\'s QR code.';

  @override
  String get errorCameraDenied =>
      'Settle needs the camera to scan. Allow it in Settings, or type the code.';

  @override
  String get errorCamera =>
      'The camera isn\'t available. Type the code instead.';

  @override
  String get claimTitle => 'Which one are you?';

  @override
  String get claimBody =>
      'Pick your name so expenses added for you come with you.';

  @override
  String get claimNotListed => 'I\'m not listed';

  @override
  String claimRejoin(String name) {
    return 'Rejoin as $name';
  }

  @override
  String joinedGroup(String group) {
    return 'Khush aamdeed! You\'re in $group.';
  }

  @override
  String get overallLabel => 'Overall';

  @override
  String get groupsLabel => 'Groups';

  @override
  String balanceYouOwe(String amount) {
    return 'You owe $amount';
  }

  @override
  String balanceYouAreOwed(String amount) {
    return 'You are owed $amount';
  }

  @override
  String get balanceAllSettled => 'You\'re all settled up';

  @override
  String balanceBothLine(String owe, String owed) {
    return 'You owe $owe · You are owed $owed';
  }

  @override
  String rowYouOwe(String amount) {
    return 'you owe $amount';
  }

  @override
  String rowYouAreOwed(String amount) {
    return 'you are owed $amount';
  }

  @override
  String get rowSettled => 'settled up';

  @override
  String memberOwes(String amount) {
    return 'owes $amount';
  }

  @override
  String memberIsOwed(String amount) {
    return 'is owed $amount';
  }

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String groupSubtitle(String type, String members) {
    return '$type · $members';
  }

  @override
  String get newGroupOrJoin => 'New group or join';

  @override
  String get tabExpenses => 'Expenses';

  @override
  String get tabBalances => 'Balances';

  @override
  String get tabSettleUp => 'Settle up';

  @override
  String get settleEveryoneSettled => 'Hisaab barabar. Everyone is settled up.';

  @override
  String transferPays(String from, String to) {
    return '$from pays $to';
  }

  @override
  String get youLabel => 'You';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get accountSection => 'Account';

  @override
  String get nameRow => 'Name';

  @override
  String get emailRow => 'Email';

  @override
  String get passwordRow => 'Password';

  @override
  String get googleOnlyAccount => 'You sign in with Google';

  @override
  String get changeNameTitle => 'Your name';

  @override
  String get nameUpdated => 'Name updated';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get currentPasswordLabel => 'Current password';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get errorCurrentPasswordWrong => 'That isn\'t your current password.';

  @override
  String get placeholderRemove => 'Remove';

  @override
  String placeholderRemoved(String name) {
    return '$name removed';
  }

  @override
  String placeholderNotSettled(String name, String amount) {
    return '$name has a balance of $amount. Settle up before removing them.';
  }

  @override
  String get deleteGroupButton => 'Delete group';

  @override
  String deleteGroupDialogTitle(String group) {
    return 'Delete $group?';
  }

  @override
  String get deleteGroupDialogBody =>
      'You\'re the only member left. This deletes the group, its expenses and its history. It can\'t be undone.';

  @override
  String get deleteGroupConfirm => 'Delete';

  @override
  String groupDeleted(String group) {
    return '$group deleted';
  }

  @override
  String get addExpenseTitle => 'Add expense';

  @override
  String get addExpenseButton => 'Add expense';

  @override
  String get amountLabel => 'Amount';

  @override
  String get currencyPrefix => 'Rs';

  @override
  String get expenseTitleLabel => 'What was it for?';

  @override
  String get expenseTitleHint => 'Chai, dinner, petrol';

  @override
  String get paidByRow => 'Paid by';

  @override
  String get splitRow => 'Split';

  @override
  String splitEqually(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return 'Equally between $_temp0';
  }

  @override
  String get dateRow => 'Date';

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String get whoPaidTitle => 'Who paid?';

  @override
  String splitEach(String amount) {
    return '$amount each';
  }

  @override
  String get errorAmountRequired => 'Enter an amount.';

  @override
  String get errorAmountTooLarge => 'That\'s more than Rs 1,000,000,000.';

  @override
  String get errorExpenseTitleRequired => 'Add what it was for.';

  @override
  String get errorPickSomeone => 'Pick at least one person.';

  @override
  String get expenseAdded => 'Done! Expense add ho gaya';

  @override
  String get undoButton => 'Undo';

  @override
  String expensePaidBy(String name, String amount) {
    return '$name paid $amount';
  }

  @override
  String expenseYouPaid(String amount) {
    return 'You paid $amount';
  }

  @override
  String rowYouLent(String amount) {
    return 'you lent $amount';
  }

  @override
  String get rowNotInvolved => 'not involved';

  @override
  String get rowEven => 'your share is paid';

  @override
  String get pickGroupTitle => 'Add to which group?';

  @override
  String get doneButton => 'Done';

  @override
  String get stackYouOwe => 'you owe';

  @override
  String get stackYouAreOwed => 'you are owed';

  @override
  String transferYouPay(String name) {
    return 'You pay $name';
  }

  @override
  String transferPaysYou(String name) {
    return '$name pays you';
  }

  @override
  String get settleYoursLabel => 'Your payments';

  @override
  String get settleOthersLabel => 'Others in the group';

  @override
  String get stackOwes => 'owes';

  @override
  String get stackIsOwed => 'is owed';

  @override
  String get iPaidButton => 'I paid';

  @override
  String get recordPaymentButton => 'Record payment';

  @override
  String get remindButton => 'Remind';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get notReceivedButton => 'Not received';

  @override
  String get cancelPaymentButton => 'Cancel payment';

  @override
  String payTitle(String name) {
    return 'Pay $name';
  }

  @override
  String recordTitle(String name) {
    return 'Payment from $name';
  }

  @override
  String balanceYouOweName(String name, String amount) {
    return 'You owe $name $amount';
  }

  @override
  String balanceNameOwesYou(String name, String amount) {
    return '$name owes you $amount';
  }

  @override
  String pendingSaysPaidYou(String name) {
    return '$name says they paid you';
  }

  @override
  String pendingYouPaid(String name) {
    return 'You paid $name';
  }

  @override
  String pendingWaitingFor(String name) {
    return 'Waiting for $name to confirm';
  }

  @override
  String paymentSentToConfirm(String name) {
    return 'Sent to $name to confirm';
  }

  @override
  String get paymentRecorded => 'Payment recorded';

  @override
  String get paymentConfirmed => 'Payment confirmed';

  @override
  String get paymentNotReceived => 'Marked as not received';

  @override
  String get paymentCancelled => 'Payment cancelled';

  @override
  String remindTitle(String name) {
    return 'Remind $name';
  }

  @override
  String get remindMessageLabel => 'Message';

  @override
  String get remindSendButton => 'Send on WhatsApp';

  @override
  String remindMessage(String amount, String group) {
    return 'Salam! $amount for $group is pending on Settle.';
  }

  @override
  String pendingToConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments to confirm',
      one: '1 payment to confirm',
    );
    return '$_temp0';
  }

  @override
  String paymentRowYouPaid(String name) {
    return 'You paid $name';
  }

  @override
  String paymentRowPaidYou(String name) {
    return '$name paid you';
  }

  @override
  String paymentRowPaid(String from, String to) {
    return '$from paid $to';
  }

  @override
  String get paymentRowLabel => 'Payment';

  @override
  String get rowSettledExpense => 'settled';

  @override
  String get heroYouAreOwed => 'You are owed';

  @override
  String get heroYouOwe => 'You owe';

  @override
  String get heroYourBalance => 'Your balance';

  @override
  String get heroAllSettled => 'All settled';

  @override
  String pendingSaysPaidAmount(String amount) {
    return 'Says they paid $amount';
  }

  @override
  String pendingWaitingAmount(String name, String amount) {
    return '$amount sent, waiting for $name to confirm';
  }

  @override
  String get splitTitle => 'Split';

  @override
  String splitTitleAmount(String amount) {
    return 'Split $amount';
  }

  @override
  String get splitModeEqual => 'Equal';

  @override
  String get splitModeExact => 'Exact';

  @override
  String get splitModePercent => '%';

  @override
  String get splitHintEqual => 'Tick who was there.';

  @override
  String get splitHintExact => 'Enter what each person owes.';

  @override
  String get splitHintPercent => 'Enter each person\'s percentage.';

  @override
  String splitLeftToAssign(String amount) {
    return '$amount left to assign';
  }

  @override
  String splitTooMuch(String amount) {
    return '$amount too much';
  }

  @override
  String splitAddsUp(String amount) {
    return 'Adds up to $amount';
  }

  @override
  String get splitAmountFirst => 'Enter the amount first.';

  @override
  String get splitByExact => 'Exact amounts';

  @override
  String get splitByPercent => 'By percentage';

  @override
  String splitYourShare(String amount) {
    return 'Your share $amount';
  }

  @override
  String get percentSuffix => '%';

  @override
  String get payersMore => 'More than one person';

  @override
  String payersTitleAmount(String amount) {
    return 'Who paid $amount?';
  }

  @override
  String get payersHint => 'Enter what each person paid.';

  @override
  String paidByTwo(String first, String second) {
    return '$first and $second';
  }

  @override
  String paidByMany(String first, int count) {
    return '$first and $count others';
  }

  @override
  String expenseManyPaid(int count, String amount) {
    return '$count people paid $amount';
  }

  @override
  String get itemsOpen => 'Split a bill by items';

  @override
  String get itemsEdit => 'Edit items';

  @override
  String get itemsTitle => 'Split by items';

  @override
  String get itemsSection => 'Items';

  @override
  String get itemsAdd => 'Add item';

  @override
  String get itemAddTitle => 'Add item';

  @override
  String get itemEditTitle => 'Edit item';

  @override
  String get itemNameLabel => 'Item';

  @override
  String get itemNameHint => 'e.g. Steak';

  @override
  String get itemPriceLabel => 'Price';

  @override
  String get itemWhoHad => 'Who had it?';

  @override
  String get itemEveryone => 'Everyone';

  @override
  String get itemUnnamed => 'Item';

  @override
  String get itemSaveButton => 'Save item';

  @override
  String get itemDeleteButton => 'Delete item';

  @override
  String get extrasSection => 'Tax, service and tip';

  @override
  String get taxLabel => 'Tax';

  @override
  String get serviceLabel => 'Service charge';

  @override
  String get tipLabel => 'Tip';

  @override
  String get whoOwesSection => 'Who owes what';

  @override
  String billTotal(String amount) {
    return 'Bill total $amount';
  }

  @override
  String billTotalChanges(String amount) {
    return 'The amount changes from $amount';
  }

  @override
  String billAddsUpTo(String amount) {
    return 'The bill adds up to $amount';
  }

  @override
  String get errorItemsNeeded => 'Add at least one item.';

  @override
  String get errorItemNeedsPeople => 'Pick who had each item.';

  @override
  String get errorPickWhoHad => 'Pick who had it.';

  @override
  String get splitByItems => 'By items';

  @override
  String get unitSwitchHint => 'Switch between % and Rs';

  @override
  String get extrasByOrderNote =>
      'Tax and service charge are shared by what each person ordered.';

  @override
  String get tipGiverLabel => 'Who gives the tip';

  @override
  String get tipGiverTitle => 'Who gives the tip?';

  @override
  String get tipEveryone => 'Everyone, equally';
}
