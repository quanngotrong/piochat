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
      const res = await fetch("/api/upload", {
        method: "POST",
        body: formData,
      });

      const data = await res.json();
      if (data.error) throw new Error(data.error);

      const imageUrl = data.url;

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