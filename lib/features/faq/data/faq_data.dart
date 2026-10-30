import '../domain/entities/faq_item.dart';

class FaqCategories {
  static const String all = 'All';
  static const String accountRegistration = 'Account & Registration';
  static const String profileManagement = 'Profile Management';
  static const String postsSocial = 'Posts & Social Features';
  static const String chatCalls = 'Chat & Calls';
  static const String libraryLearning = 'Library & Learning';
  static const String notifications = 'Notifications';
  static const String privacySecurity = 'Privacy & Security';

  static const List<String> list = [
    all,
    accountRegistration,
    profileManagement,
    postsSocial,
    chatCalls,
    libraryLearning,
    notifications,
    privacySecurity,
  ];
}

final List<FaqItem> initialFaqData = [
  // Account & Registration
  FaqItem(
    id: 'ar_1',
    category: FaqCategories.accountRegistration,
    question: 'How do I create an EduNest account?',
    answer:
        'You can register with your university or personal email address, or sign in directly with your Google account. After sign-up, you will be prompted to complete your academic profile with your university name and major.',
    tags: ['sign up', 'register', 'google', 'account'],
    helpfulCount: 42,
    unhelpfulCount: 1,
  ),
  FaqItem(
    id: 'ar_2',
    category: FaqCategories.accountRegistration,
    question: 'Can I change my registered email address later?',
    answer:
        'Yes. Go to the Drawer > Privacy and Security > Change Email. Enter your new email address, and EduNest will send a verification link to confirm before updating your account records.',
    tags: ['email', 'change', 'verification'],
    helpfulCount: 29,
    unhelpfulCount: 0,
  ),
  FaqItem(
    id: 'ar_3',
    category: FaqCategories.accountRegistration,
    question: 'What should I do if I forgot my password?',
    answer:
        'On the login screen, tap "Forgot Password?" and enter your registered email address. You will receive a password reset link to create a new password securely.',
    tags: ['password', 'reset', 'forgot'],
    helpfulCount: 38,
    unhelpfulCount: 2,
  ),

  // Profile Management
  FaqItem(
    id: 'pm_1',
    category: FaqCategories.profileManagement,
    question: 'How do I update my major, university, and bio?',
    answer:
        'Open the side drawer and select "Edit Profile". You can modify your full name, bio, university, major, year, semester, date of birth, and avatar image. Tap "Save" to apply changes immediately across EduNest.',
    tags: ['profile', 'major', 'university', 'edit', 'bio'],
    helpfulCount: 51,
    unhelpfulCount: 1,
  ),
  FaqItem(
    id: 'pm_2',
    category: FaqCategories.profileManagement,
    question: 'How do I upload or update my profile photo?',
    answer:
        'In "Edit Profile", tap the camera icon on your avatar. Choose a photo from your gallery or capture one with your camera. EduNest compresses and uploads it to secure cloud storage automatically.',
    tags: ['avatar', 'photo', 'picture', 'camera'],
    helpfulCount: 34,
    unhelpfulCount: 0,
  ),

  // Posts & Social Features
  FaqItem(
    id: 'ps_1',
    category: FaqCategories.postsSocial,
    question: 'Who can see my posts on EduNest?',
    answer:
        'When creating or editing a post, you can choose its privacy audience: "Public" (visible to all students and educators on EduNest), "Friend" (visible only to mutual followers), or "Only Me" (private personal archive).',
    tags: ['posts', 'privacy', 'public', 'friends', 'feed'],
    helpfulCount: 67,
    unhelpfulCount: 3,
  ),
  FaqItem(
    id: 'ps_2',
    category: FaqCategories.postsSocial,
    question: 'What happens when I delete a post? Can I recover it?',
    answer:
        'EduNest uses a 30-day safety retention period. Deleted posts move to your "Archive > Recently Deleted" section where you can restore them or permanently delete them at any time. Posts are automatically purged after 30 days.',
    tags: ['delete', 'archive', 'restore', 'recover', '30 days'],
    helpfulCount: 89,
    unhelpfulCount: 2,
  ),
  FaqItem(
    id: 'ps_3',
    category: FaqCategories.postsSocial,
    question: 'How do I mention or tag classmates in posts?',
    answer:
        'Type "@" followed by their username while drafting your post. A suggestions popup will appear. Mentioned classmates receive an instant notification directing them to the post.',
    tags: ['tag', 'mention', 'classmate', 'notification'],
    helpfulCount: 45,
    unhelpfulCount: 1,
  ),

  // Chat & Calls
  FaqItem(
    id: 'cc_1',
    category: FaqCategories.chatCalls,
    question: 'How do direct messaging and study group chats work?',
    answer:
        'Visit the Chat tab to start 1-on-1 conversations or create group chats for class projects. You can share text, images, audio voice notes, and documents in real time.',
    tags: ['chat', 'messages', 'groups', 'voice', 'files'],
    helpfulCount: 56,
    unhelpfulCount: 0,
  ),
  FaqItem(
    id: 'cc_2',
    category: FaqCategories.chatCalls,
    question: 'Can I make audio and video calls on EduNest?',
    answer:
        'Yes! EduNest integrates high-definition audio and video calling powered by ZegoCloud. Tap the phone or video icon inside any direct chat to start an instant call with your classmate.',
    tags: ['call', 'video', 'audio', 'zegocloud'],
    helpfulCount: 62,
    unhelpfulCount: 2,
  ),

  // Library & Learning
  FaqItem(
    id: 'll_1',
    category: FaqCategories.libraryLearning,
    question: 'How do I access textbooks, lecture slides, and PDFs?',
    answer:
        'Tap the Library tab in the bottom navigation. Browse categorized academic courses, download or preview PDF lecture notes directly in the built-in reader, and bookmark favorite resources.',
    tags: ['library', 'pdf', 'books', 'lecture notes', 'resources'],
    helpfulCount: 78,
    unhelpfulCount: 1,
  ),
  FaqItem(
    id: 'll_2',
    category: FaqCategories.libraryLearning,
    question: 'How do I save posts or study resources for later?',
    answer:
        'Tap the bookmark icon on any post or library material. You can access all your bookmarked items anytime from the side drawer under "Saved Resource".',
    tags: ['bookmark', 'save', 'saved resource', 'study'],
    helpfulCount: 43,
    unhelpfulCount: 0,
  ),

  // Notifications
  FaqItem(
    id: 'nt_1',
    category: FaqCategories.notifications,
    question: 'What notifications will I receive?',
    answer:
        'You receive notifications when someone likes your post, comments, mentions you, sends a follow request, or schedules a reminder. You can view all activity in the Notifications page.',
    tags: ['notifications', 'alerts', 'likes', 'comments'],
    helpfulCount: 31,
    unhelpfulCount: 1,
  ),
  FaqItem(
    id: 'nt_2',
    category: FaqCategories.notifications,
    question: 'How do I manage study reminders and todo alerts?',
    answer:
        'Go to the Reminder section from the drawer to set study alarms, exam dates, and assignment deadlines with customizable local sound alerts.',
    tags: ['reminder', 'todo', 'alarm', 'schedule'],
    helpfulCount: 28,
    unhelpfulCount: 0,
  ),

  // Privacy & Security
  FaqItem(
    id: 'ps_sec_1',
    category: FaqCategories.privacySecurity,
    question: 'How do I change my password or secure my account?',
    answer:
        'Navigate to Drawer > Privacy and Security > Change Password. Create a strong password containing at least 8 characters with numbers, lowercase, uppercase, and special characters.',
    tags: ['password', 'security', 'protection'],
    helpfulCount: 54,
    unhelpfulCount: 1,
  ),
  FaqItem(
    id: 'ps_sec_2',
    category: FaqCategories.privacySecurity,
    question: 'How does user blocking work on EduNest?',
    answer:
        'If you block a user, they will not be able to message or call you, view your profile details, or interact with your posts. You can manage and unblock users at any time under Privacy and Security > Blocked Users.',
    tags: ['block', 'unblock', 'privacy', 'safety'],
    helpfulCount: 49,
    unhelpfulCount: 2,
  ),
  FaqItem(
    id: 'ps_sec_3',
    category: FaqCategories.privacySecurity,
    question: 'What is OTP verification and when is it required?',
    answer:
        'One-Time Password (OTP) verification adds a layer of security for critical actions like resetting credentials or changing email addresses. Codes expire in 10 minutes and allow a maximum of 5 attempts.',
    tags: ['otp', '2fa', 'verification', 'code', 'security'],
    helpfulCount: 39,
    unhelpfulCount: 0,
  ),
  FaqItem(
    id: 'ps_sec_4',
    category: FaqCategories.privacySecurity,
    question: 'Can I permanently delete my account and data?',
    answer:
        'Yes. You can request permanent account deletion under Drawer > Account Status > Delete Account. This removes your authentication credentials, posts, comments, likes, and profile data from our databases permanently.',
    tags: ['delete account', 'data privacy', 'retention', 'gdpr'],
    helpfulCount: 37,
    unhelpfulCount: 1,
  ),
];
