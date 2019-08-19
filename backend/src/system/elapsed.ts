import { ConsoleLogger } from "@yingyeothon/logger";
import timespan from "time-span";
import envars from "./envars";

const logger = new ConsoleLogger(
  envars.logging.debug || envars.logging.elapsed ? `debug` : `info`
);

interface ISample {
  totalElapsed: number;
  callCount: number;
}

const emptySample = (): ISample => ({ totalElapsed: 0, callCount: 0 });

interface IStat {
  success: ISample;
  fail: ISample;
}

const stats: { [name: string]: IStat } = {};

const emptyStat = (): IStat => ({
  success: emptySample(),
  fail: emptySample()
});

const collect = (name: string, type: "success" | "fail", took: number) => {
  if (!stats[name]) {
    stats[name] = emptyStat();
  }
  stats[name][type].totalElapsed += took;
  stats[name][type].callCount++;
};

export const reportStats = () => {
  for (const name of Object.keys(stats)) {
    const { success: s, fail: f } = stats[name];
    if (s.callCount > 0) {
      logger.info(
        `Elapsed[${name}] avg took ${s.totalElapsed / s.callCount} with ${
          s.callCount
        } samples`
      );
    }
    if (f.callCount > 0) {
      logger.info(
        `Elapsed[${name}] avg took ${f.totalElapsed / f.callCount} with ${
          f.callCount
        } fail samples`
      );
    }
  }
};

const elapsed = <ArgumentTypes extends unknown[], ReturnType>(
  name: string,
  func: (...args: ArgumentTypes) => ReturnType
): ((...args: ArgumentTypes) => ReturnType) => {
  return (...args: ArgumentTypes): ReturnType => {
    const span = timespan();
    const finish = (result: ReturnType) => {
      const took = span();
      collect(name, "success", took);
      logger.debug(`Elapsed[${name}]`, took);
      return result;
    };
    const fail = (error: Error) => {
      const took = span();
      collect(name, "success", took);
      logger.debug(`Elapsed[${name}]`, took, `withError`, error);
      throw error;
    };
    try {
      const result = func(...args);
      return result instanceof Promise
        ? (result.then(finish).catch(fail) as any)
        : finish(result);
    } catch (error) {
      return fail(error);
    }
  };
};

export default elapsed;
