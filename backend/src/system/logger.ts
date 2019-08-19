import { ConsoleLogger } from "@yingyeothon/logger";
import envars from "./envars";

const logger = new ConsoleLogger(envars.logging.debug ? "debug" : "info");
export default logger;
