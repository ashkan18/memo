export const interestTypeString = (type: string) => {
  switch (type) {
    case "listened":
      return "listened to";
    case "watched":
      return "watched";
    case "saw":
      return "saw";
    case "read":
      return "read";
  }
};
