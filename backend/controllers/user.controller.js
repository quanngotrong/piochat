import * as dynamoDB from "../db/dynamoDB.js";

export const getUsersForSidebar = async (req, res) => {
  try {
    const loggedInUsename = req.user.username;

    const filteredUsers = await dynamoDB.getOtherUsers(loggedInUsename)

    res.status(200).json(filteredUsers);
  } catch (error) {
    console.error("Error in getUsersForSidebar: ", error.message);
    res.status(500).json({ error: "Internal server error" });
  }
};
