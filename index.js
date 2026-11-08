// functions/index.js  (Node 20, firebase-functions v2)
// Sends a push notification to every other participant whenever a new
// message is created in chats/{chatId}/messages/{msgId}.

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

function preview(m) {
  switch (m.type) {
    case 'image':   return '📷 Photo';
    case 'audio':   return '🎤 Voice message';
    case 'sticker': return '🙂 Sticker';
    case 'poll':    return `📊 ${m.text || 'Poll'}`;
    case 'file':    return `📎 ${m.fileName || 'File'}`;
    default:        return m.text || '';
  }
}

exports.onChatMessage = onDocumentCreated(
  'chats/{chatId}/messages/{msgId}',
  async (event) => {
    const msg = event.data && event.data.data();
    if (!msg || msg.type === 'system' || msg.isUnsent) return;

    const { chatId } = event.params;
    const chatRef = db.collection('chats').doc(chatId);
    const chat = (await chatRef.get()).data();
    if (!chat) return;

    const senderId = msg.senderId;
    const isGroup = chat.isGroup === true;
    const recipients = (chat.participants || []).filter((u) => u !== senderId);
    if (recipients.length === 0) return;

    // names (cached for this run)
    const names = {};
    const nameOf = async (uid) => {
      if (names[uid]) return names[uid];
      const d = (await db.collection('users').doc(uid).get()).data() || {};
      names[uid] = (d.name || d.username || 'Someone').toString();
      return names[uid];
    };

    const title = isGroup ? chat.groupName || 'Group' : await nameOf(senderId);

    // latest messages, newest first (used to build the stacked lines)
    const recent = await chatRef
      .collection('messages')
      .orderBy('timestamp', 'desc')
      .limit(15)
      .get();

    await Promise.all(
      recipients.map(async (uid) => {
        const userRef = db.collection('users').doc(uid);
        const user = (await userRef.get()).data() || {};

        // skip blocked senders and muted chats
        if ((user.blockedUsers || []).includes(senderId)) return;
        if ((user.mutedChats || []).includes(chatId)) return; // <-- adapt to how ChatService stores mute

        const tokens = [
          ...new Set([
            ...(user.fcmTokens || []),
            ...(user.fcmToken ? [user.fcmToken] : []),
          ]),
        ];
        if (tokens.length === 0) return;

        // show up to 5 of the user's unread messages, oldest first
        const unread = Math.min(Number(chat[`unreadCount_${uid}`] || 1), 5);
        const picked = [];
        for (const d of recent.docs) {
          const m = d.data();
          if (m.type === 'system' || m.isUnsent) continue;
          if (m.senderId === uid) continue;
          if ((user.blockedUsers || []).includes(m.senderId)) continue;
          if ((m.deletedFor || []).includes(uid)) continue;
          picked.push(m);
          if (picked.length >= unread) break;
        }
        picked.reverse();

        const lines = [];
        for (const m of picked) {
          const text = preview(m);
          lines.push(isGroup ? `${await nameOf(m.senderId)}: ${text}` : text);
        }
        if (lines.length === 0) lines.push(preview(msg));

        const res = await admin.messaging().sendEachForMulticast({
          tokens,
          // data-only: the app builds the notification itself
          data: {
            chatId,
            title,
            isGroup: String(isGroup),
            lines: JSON.stringify(lines),
          },
          android: { priority: 'high' },
          webpush: { headers: { Urgency: 'high' } },
        });

        // clean up dead tokens
        const dead = [];
        res.responses.forEach((r, i) => {
          const code = r.error && r.error.code;
          if (
            code === 'messaging/registration-token-not-registered' ||
            code === 'messaging/invalid-registration-token'
          ) {
            dead.push(tokens[i]);
          }
        });
        if (dead.length) {
          await userRef.update({
            fcmTokens: admin.firestore.FieldValue.arrayRemove(...dead),
          });
        }
      })
    );
  }
);