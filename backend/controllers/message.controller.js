import { getReceiverSocketId, io } from "../socket/socket.js";
import * as dynamoDB from "../db/dynamoDB.js";
import { parse } from "path";
import * as s3Util from "../utils/s3.js";

export const sendMessage = async (req, res) => {
  try {
    const { message, type } = req.body;
    const { username: receiverUsername } = req.params;
    const senderUsername = req.user.username;

    let conversation = await dynamoDB.getConversation([
      senderUsername,
      receiverUsername,
    ]);

    if (!conversation) {
      conversation = await dynamoDB.createConversation([
        senderUsername,
        receiverUsername,
      ]);
    }

    const newMessage = await dynamoDB.createMessage(
      conversation.conversationId,
      senderUsername,
      message,
      type,
    );

    if (newMessage) {
      await dynamoDB.addMessageToConversation(
        conversation.conversationId,
        newMessage.messageId,
      );
    }

    // SOCKET IO FUNCTIONALITY WILL GO HERE
    const receiverSocketId = getReceiverSocketId(receiverUsername);
    if (receiverSocketId) {
      // io.to(<socket_id>).emit() used to send events to specific client
      io.to(receiverSocketId).emit("newMessage", newMessage);
    }

    res.status(201).json(newMessage);
  } catch (error) {
    console.log("Error in sendMessage controller: ", error.message);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const getMessages = async (req, res) => {
  try {
    const { username: userToChatUsername } = req.params;
    const senderUsername = req.user.username;

    const conversation = await dynamoDB.getConversation([
      senderUsername,
      userToChatUsername,
    ]);

    if (!conversation) return res.status(200).json([]);

    const messages = await dynamoDB.getMessagesByConversationId(
      conversation.conversationId,
    );

    res.status(200).json(messages);
  } catch (error) {
    console.log("Error in getMessages controller: ", error.message);
    res.status(500).json({ error: "Internal server error" });
  }
};
export const getUploadPresignedUrl = async (req, res) => {
  try {
    const filename = req.body.filename;

    const { name, ext } = parse(filename);
    const newFilename = `${Date.now()}${ext}_${name}`;

    const key = `messages/images/${newFilename}`;
    const result = await s3Util.genUploadPresignedUrl(key);
    res.status(200).json({ ...result, key });
  } catch (error) {
    console.log("Error in getUploadPresignedUrl controller: ", error.message);
    res.status(500).json({ error: "Internal server error" });
  }
};
