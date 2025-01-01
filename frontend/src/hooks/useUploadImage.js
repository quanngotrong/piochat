import { useState } from "react";
import useConversation from "../zustand/useConversation";
import toast from "react-hot-toast";

const useUploadImage = () => {
  const [loading, setLoading] = useState(false);
  const { messages, setMessages, selectedConversation } = useConversation();

  const uploadImage = async (file) => {
    setLoading(true);
    try {
      const formData = new FormData();
      formData.append("file", file);

      // upload s3 here
      let res = await fetch("/api/messages/presigned-url", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ filename: file.name }),
      });
      res = await res.json();

      if (!res) throw new Error(res);

      await fetch(res.url, {
        method: "PUT",
        body: file,
        headers: {
          "Content-Type": file.type,
        },
      });

      const imageUrl = res.key;

      const messageRes = await fetch(
        `/api/messages/send/${selectedConversation.username}`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ message: imageUrl, type: "image" }),
        },
      );

      const messageData = await messageRes.json();
      if (messageData.error) throw new Error(messageData.error);

      setMessages([...messages, messageData]);
    } catch (error) {
      toast.error(error.message);
    } finally {
      setLoading(false);
    }
  };

  return { uploadImage, loading };
};

export default useUploadImage;

