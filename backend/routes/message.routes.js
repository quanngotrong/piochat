import express from "express";
import { getMessages, sendMessage, getUploadPresignedUrl } from "../controllers/message.controller.js";
import protectRoute from "../middleware/protectRoute.js";

const router = express.Router();

router.get("/:username", protectRoute, getMessages);
router.post("/send/:username", protectRoute, sendMessage);
router.post("/presigned-url", protectRoute, getUploadPresignedUrl);

export default router;
