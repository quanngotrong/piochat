import jwt from "jsonwebtoken";
import * as dynamoDB from "../db/dynamoDB.js";

const protectRoute = async (req, res, next) => {
  try {
    const token = req.cookies.jwt;

    if (!token) {
      return res
        .status(401)
        .json({ error: "Unauthorized - No Token Provided" });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    if (!decoded) {
      return res.status(401).json({ error: "Unauthorized - Invalid Token" });
    }

    console.log(decoded);
    const userResult = await dynamoDB.findUserByUsername(decoded.username);
    console.log(userResult);

    if (!userResult.Item) {
      return res.status(404).json({ error: "User not found" });
    }
    const user = userResult.Item;

    req.user = user;

    next();
  } catch (error) {
    console.log("Error in protectRoute middleware: ", error.message);
    res.status(500).json({ error: "Internal server error" });
  }
};

export default protectRoute;
