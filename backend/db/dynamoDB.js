import AWS from "aws-sdk";

// AWS.config.update({
//   accessKeyId: process.env.accessKeyId,
//   secretAccessKey: process.env.secretAccessKey,
//   region: process.env.region,
//   endpoint: process.env.endpoint,
// });

AWS.config.update({
  region: process.env.AWS_REGION || "ap-southeast-1",
});

export const db = new AWS.DynamoDB.DocumentClient({ convertEmptyValues: true });

export const findUserByUsername = async (username) => {
  const params = {
    TableName: "Users",
    Key: {
      username: username,
    },
  };
  const user = await db.get(params).promise();
  return user;
};

export const createUser = async (userItem) => {
  const newUser = {
    TableName: "Users",
    Item: userItem,
  };

  return db.put(newUser).promise();
};

export const getOtherUsers = async (username) => {
  // Scan all users except the logged-in user
  const params = {
    TableName: "Users",
    FilterExpression: "username <> :username",
    ProjectionExpression: "fullName, username, profilePic, gender",
    ExpressionAttributeValues: {
      ":username": username,
    },
  };

  const result = await db.scan(params).promise();
  const filteredUsers = result.Items;
  return filteredUsers;
};

export const createConversation = async (participants) => {
  const conversationId = AWS.util.uuid.v4(); // Generate a unique ID for the conversation
  const params = {
    TableName: "Conversations",
    Item: {
      conversationId,
      participants,
      messages: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    },
  };

  await db.put(params).promise();
  return params.Item;
};

export const getConversation = async (participants) => {
  const params = {
    TableName: "Conversations",
    FilterExpression: "contains(participants, :sender) and contains(participants, :receiver)",
    ExpressionAttributeValues: {
      ":sender": participants[0],
      ":receiver": participants[1],
    },
  };

  const result = await db.scan(params).promise();
  return result.Items[0];
};

export const addMessageToConversation = async (conversationId, messageId) => {
  const params = {
    TableName: "Conversations",
    Key: {
      conversationId,
    },
    UpdateExpression: "SET messages = list_append(messages, :messageId), updatedAt = :updatedAt",
    ExpressionAttributeValues: {
      ":messageId": [messageId],
      ":updatedAt": new Date().toISOString(),
    },
    ReturnValues: "ALL_NEW",
  };

  const result = await db.update(params).promise();
  return result.Attributes;
};

export const createMessage = async (conversationId, senderId, content, type) => {
  const messageId = AWS.util.uuid.v4(); // Generate a unique ID for the message
  const params = {
    TableName: "Messages",
    Item: {
      messageId,
      conversationId,
      senderId,
      content,
      type,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    },
  };

  await db.put(params).promise();
  return params.Item;
};

export const getMessagesByConversationId = async (conversationId) => {
	try {
		const params = {
			TableName: "Messages",
			KeyConditionExpression: "conversationId = :conversationId",
			ExpressionAttributeValues: {
				":conversationId": conversationId,
			},
		};

		const result = await db.query(params).promise();
		return result.Items || [];
	} catch (error) {
		console.error("Error retrieving messages by conversationId: ", error.message);
		throw new Error("Failed to fetch messages");
	}
};
