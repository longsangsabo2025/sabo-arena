# 🗄️ SUPABASE SCHEMA AUDIT REPORT

*Generated: D:\0.APP\2210\saboarenav4*

---

## 📊 Summary

- **Supabase Tables:** 18
- **Dart Models:** 26

---

## 🗄️ Supabase Tables

- ❌ `achievements` → Achievements
- ❌ `challenges` → Challenges
- ❌ `chat_messages` → ChatMessages
- ❌ `chat_rooms` → ChatRooms
- ❌ `club_members` → ClubMembers
- ❌ `club_reviews` → ClubReviews
- ❌ `clubs` → Clubs
- ❌ `matches` → Matches
- ❌ `notifications` → Notifications
- ❌ `post_comments` → PostComments
- ❌ `post_likes` → PostLikes
- ❌ `posts` → Posts
- ❌ `rank_requests` → RankRequests
- ❌ `saved_posts` → SavedPosts
- ❌ `table_reservations` → TableReservations
- ❌ `tournament_participants` → TournamentParticipants
- ❌ `tournaments` → Tournaments
- ❌ `users` → Users

---

## 💻 Dart Models

### Achievement

**File:** `lib\models\achievement.dart`

**Fields:** 12

```dart
  id
  name
  description
  category
  iconUrl
  badgeColor
  pointsRequired
  winsRequired
  tournamentsRequired
  earnedAt
  tournamentTitle
  isEarned
```

### AdminUserView

**File:** `lib\models\admin_user_view.dart`

**Fields:** 17

```dart
  id
  email
  fullName
  displayName
  avatarUrl
  phone
  role
  status
  rank
  eloRating
  isVerified
  createdAt
  blockedAt
  blockedReason
  totalWins
  totalLosses
  totalTournaments
```

### AdvancedFilters

**File:** `lib\models\member_data.dart`

**Fields:** 33

```dart
  minRank
  maxRank
  minElo
  maxElo
  joinStartDate
  joinEndDate
  id
  user
  membershipInfo
  activityStats
  id
  name
  username
  avatar
  elo
  rank
  isOnline
  displayName
  email
  phone
  location
  bio
  membershipId
  joinDate
  status
  type
  autoRenewal
  expiryDate
  activityScore
  winRate
  totalMatches
  lastActive
  tournamentsJoined
```

### AvailableSlot

**File:** `lib\models\reservation_models.dart`

**Fields:** 38

```dart
  startTime
  endTime
  pricePerHour
  clubId
  userId
  tableNumber
  startTime
  endTime
  durationHours
  pricePerHour
  totalPrice
  depositAmount
  paymentMethod
  notes
  specialRequests
  numberOfPlayers
  id
  clubId
  tableNumber
  date
  timeSlot
  isAvailable
  reason
  totalReservations
  pendingReservations
  confirmedReservations
  completedReservations
  cancelledReservations
  totalRevenue
  expectedRevenue
  averageBookingValue
  startTime
  durationHours
  isAvailable
  startDate
  endDate
  tableNumber
  userId
```

### Club

**File:** `lib\models\club.dart`

**Fields:** 26

```dart
  id
  ownerId
  name
  description
  address
  phone
  email
  websiteUrl
  coverImageUrl
  profileImageUrl
  logoUrl
  establishedYear
  totalTables
  pricePerHour
  isVerified
  isActive
  approvalStatus
  rejectionReason
  approvedAt
  approvedBy
  rating
  totalReviews
  latitude
  longitude
  createdAt
  updatedAt
```

### ClubMember

**File:** `lib\models\club_member.dart`

**Fields:** 10

```dart
  id
  userId
  clubId
  role
  joinedAt
  isActive
  userName
  userAvatar
  userRank
  isOnline
```

### ClubModel

**File:** `lib\models\club_model.dart`

**Fields:** 15

```dart
  id
  name
  location
  address
  phone
  email
  description
  coverImageUrl
  profileImageUrl
  latitude
  longitude
  isActive
  isVerified
  rating
  totalReviews
```

### ClubPromotion

**File:** `lib\models\club_promotion.dart`

**Fields:** 30

```dart
  id
  clubId
  title
  description
  imageUrl
  type
  status
  startDate
  endDate
  maxRedemptions
  currentRedemptions
  discountPercentage
  discountAmount
  promoCode
  priority
  createdAt
  updatedAt
  createdBy
  value
  displayName
  value
  displayName
  id
  promotionId
  userId
  clubId
  redeemedAt
  status
  discountApplied
  transactionId
```

### ClubReview

**File:** `lib\models\club_review.dart`

**Fields:** 20

```dart
  id
  clubId
  userId
  userName
  userAvatar
  rating
  comment
  createdAt
  updatedAt
  facilityRating
  serviceRating
  atmosphereRating
  priceRating
  helpfulCount
  averageRating
  totalReviews
  averageFacilityRating
  averageServiceRating
  averageAtmosphereRating
  averagePriceRating
```

### ClubTournament

**File:** `lib\models\club_tournament.dart`

**Fields:** 15

```dart
  id
  clubId
  name
  description
  startDate
  endDate
  status
  maxParticipants
  currentParticipants
  entryFee
  prizeDescription
  tournamentType
  imageUrl
  createdAt
  updatedAt
```

### GuideStep

**File:** `lib\models\admin_guide_models.dart`

**Fields:** 27

```dart
  title
  description
  type
  imageUrl
  icon
  targetRoute
  videoUrl
  id
  title
  description
  category
  estimatedMinutes
  priority
  isNew
  version
  lastUpdated
  userId
  guideId
  currentStep
  isCompleted
  completedAt
  lastAccessedAt
  screenId
  elementId
  title
  description
  relatedGuideId
```

### Match

**File:** `lib\models\match_model.dart`

**Fields:** 5

```dart
  id
  player1
  player2
  winner
  round
```

### MemberAnalytics

**File:** `lib\models\member_analytics.dart`

**Fields:** 6

```dart
  totalMembers
  activeMembers
  newThisMonth
  growthRate
  activityRate
  retentionRate
```

### MessageModel

**File:** `lib\models\messaging_models.dart`

**Fields:** 66

```dart
  id
  chatId
  senderId
  content
  type
  replyToMessageId
  createdAt
  serverTimestamp
  editedAt
  isEdited
  status
  replyToMessage
  sender
  isEncrypted
  isForwarded
  forwardedFromChatId
  id
  name
  description
  type
  avatarUrl
  lastMessage
  createdAt
  updatedAt
  createdBy
  settings
  unreadCount
  isArchived
  isMuted
  mutedUntil
  userId
  role
  joinedAt
  leftAt
  isActive
  user
  lastSeenAt
  id
  username
  avatarUrl
  status
  lastSeenAt
  statusMessage
  messageId
  userId
  emoji
  createdAt
  user
  allowMembersToAddOthers
  allowMembersToEditInfo
  onlyAdminsCanSendMessages
  disappearingMessages
  disappearingMessagesDuration
  readReceipts
  typingIndicators
  maxParticipants
  chatId
  userId
  isTyping
  lastTypedAt
  user
  value
  value
  value
  value
  value
```

### NotificationModel

**File:** `lib\models\notification_models.dart`

**Fields:** 64

```dart
  id
  userId
  type
  title
  body
  actionUrl
  isRead
  createdAt
  readAt
  priority
  imageUrl
  sourceUserId
  sourceUserName
  sourceUserAvatar
  value
  value
  notificationId
  type
  actionUrl
  totalNotifications
  unreadCount
  readCount
  readRate
  lastNotificationAt
  lastReadAt
  id
  title
  actionUrl
  destructive
  type
  titleTemplate
  bodyTemplate
  defaultPriority
  defaultActionUrl
  enabled
  startTime
  endTime
  userId
  globalEnabled
  enablePushNotifications
  enableInAppNotifications
  enableEmailNotifications
  enableSmsNotifications
  enableQuietHours
  quietHoursStart
  quietHoursEnd
  soundSetting
  vibrationEnabled
  lastUpdated
  type
  enabled
  customSound
  useVibration
  priority
  pushEnabled
  emailEnabled
  smsEnabled
  id
  name
  description
  importance
  sound
  enableVibration
  enableLights
```

### PaymentMethod

**File:** `lib\models\payment_method.dart`

**Fields:** 34

```dart
  id
  clubId
  type
  bankName
  accountNumber
  accountName
  qrCodeUrl
  qrCodePath
  isActive
  isDefault
  createdAt
  updatedAt
  value
  displayName
  isDeveloped
  icon
  id
  tournamentId
  userId
  clubId
  paymentMethodId
  amount
  status
  proofImageUrl
  proofImagePath
  transactionNote
  transactionReference
  createdAt
  paidAt
  verifiedAt
  verifiedBy
  rejectionReason
  value
  displayName
```

### Player

**File:** `lib\models\player_model.dart`

**Fields:** 3

```dart
  id
  name
  avatarUrl
```

### Post

**File:** `lib\models\post.dart`

**Fields:** 16

```dart
  id
  userId
  content
  postType
  location
  tournamentId
  clubId
  likeCount
  commentCount
  shareCount
  isPublic
  createdAt
  updatedAt
  userName
  userAvatar
  userRank
```

### PostBackgroundTheme

**File:** `lib\models\post_background_theme.dart`

**Fields:** 7

```dart
  id
  name
  type
  imageUrl
  overlayOpacity
  overlayColor
  textStyle
```

### PostModel

**File:** `lib\models\post_model.dart`

**Fields:** 14

```dart
  id
  title
  content
  imageUrl
  videoUrl
  authorId
  authorName
  authorAvatarUrl
  createdAt
  likeCount
  commentCount
  shareCount
  isLiked
  isSaved
```

### RankRequest

**File:** `lib\models\rank_request.dart`

**Fields:** 10

```dart
  id
  userId
  clubId
  status
  requestedAt
  reviewedAt
  reviewedBy
  rejectionReason
  notes
  user
```

### TableReservation

**File:** `lib\models\table_reservation.dart`

**Fields:** 32

```dart
  id
  clubId
  userId
  tableNumber
  startTime
  endTime
  durationHours
  pricePerHour
  totalPrice
  depositAmount
  status
  paymentStatus
  paymentMethod
  paymentTransactionId
  notes
  specialRequests
  numberOfPlayers
  confirmedAt
  confirmedBy
  cancelledAt
  cancelledBy
  cancellationReason
  createdAt
  updatedAt
  club
  user
  value
  displayName
  icon
  value
  displayName
  icon
```

### Tournament

**File:** `lib\models\tournament.dart`

**Fields:** 36

```dart
  id
  title
  description
  clubId
  organizerId
  startDate
  endDate
  registrationStart
  registrationDeadline
  maxParticipants
  currentParticipants
  entryFee
  prizePool
  status
  skillLevelRequired
  format
  tournamentType
  rules
  requirements
  isPublic
  coverImageUrl
  createdAt
  updatedAt
  prizeSource
  distributionTemplate
  organizerFeePercent
  sponsorContribution
  minRank
  maxRank
  venueAddress
  venueContact
  venuePhone
  specialRules
  registrationFeeWaiver
  clubName
  clubLogo
```

### UserAchievement

**File:** `lib\models\user_achievement.dart`

**Fields:** 33

```dart
  id
  userId
  achievementId
  type
  title
  description
  iconUrl
  progressCurrent
  progressRequired
  isCompleted
  completedAt
  createdAt
  updatedAt
  id
  userId
  promotionId
  clubId
  clubName
  voucherCode
  source
  sourceId
  title
  description
  imageUrl
  type
  status
  discountAmount
  discountPercentage
  minOrderAmount
  issuedAt
  expiresAt
  usedAt
  usedAtClub
```

### UserProfile

**File:** `lib\models\user_profile.dart`

**Fields:** 24

```dart
  id
  email
  fullName
  displayName
  username
  bio
  avatarUrl
  coverPhotoUrl
  phone
  dateOfBirth
  role
  skillLevel
  rank
  totalWins
  totalLosses
  totalTournaments
  eloRating
  spaPoints
  totalPrizePool
  isVerified
  isActive
  location
  createdAt
  updatedAt
```

### VoucherCampaign

**File:** `lib\models\voucher_campaign.dart`

**Fields:** 51

```dart
  id
  clubId
  title
  description
  imageUrl
  type
  status
  startDate
  endDate
  target
  budget
  totalIssued
  totalUsed
  createdAt
  updatedAt
  createdBy
  approvedBy
  approvedAt
  rejectionReason
  value
  displayName
  value
  displayName
  type
  maxRedemptions
  maxPerUser
  value
  displayName
  total
  used
  remaining
  type
  currency
  value
  displayName
  id
  clubId
  campaignId
  status
  title
  description
  requestedBudget
  businessJustification
  requestedStartDate
  requestedEndDate
  createdAt
  updatedAt
  adminNotes
  rejectionReason
  value
  displayName
```

---

*Generated by supabase_schema_audit.py*
