import AWS from "aws-sdk";

// AWS.config.update({
//   accessKeyId: process.env.accessKeyId,
//   secretAccessKey: process.env.secretAccessKey,
//   region: process.env.region,
//   endpoint: process.env.endpoint,
// });

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
