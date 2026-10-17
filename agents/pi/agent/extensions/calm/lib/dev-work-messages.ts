import type { CustomMessageComponent as PiCustomMessageComponent } from "@earendil-works/pi-coding-agent";
import * as PiCodingAgent from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { calmChildFailureNotice, failedDevWorkOutcomeChildren } from "./dev-work-policy.ts";
import { calmHidesTranscriptChrome } from "./visibility.ts";

type MessageState = {
  message?: ConstructorParameters<typeof PiCustomMessageComponent>[0];
};
type MessagePatch = { hidesMessage: (message: MessageState["message"]) => boolean };
const CALM_WORK_MESSAGES_PATCH = Symbol.for("pi-calm:dev-work-messages:child-failures-red-spaced");
const PREVIOUS_WORK_MESSAGES_PATCHES = [
  Symbol.for("pi-calm:dev-work-messages:pi-0.85.1"),
  Symbol.for("pi-calm:dev-work-messages:child-failures-only"),
];

export function installCalmDevWorkMessageLayout(): void {
  const registry = globalThis as typeof globalThis & { [key: symbol]: MessagePatch | undefined };
  for (const key of PREVIOUS_WORK_MESSAGES_PATCHES) {
    const previous = registry[key];
    if (previous) previous.hidesMessage = () => false;
  }
  const hidesMessage: MessagePatch["hidesMessage"] = (message) =>
    calmHidesTranscriptChrome() && message?.role === "custom" &&
    message.display === true && message.customType === "dev/work-outcome";
  const installed = registry[CALM_WORK_MESSAGES_PATCH];
  if (installed) {
    installed.hidesMessage = hidesMessage;
    return;
  }
  const CustomMessageComponent = PiCodingAgent.CustomMessageComponent;
  if (typeof CustomMessageComponent !== "function" || typeof CustomMessageComponent.prototype.render !== "function") {
    throw new Error("Pi Calm requires Pi CustomMessageComponent.render");
  }
  const originalRender = CustomMessageComponent.prototype.render;
  const patch: MessagePatch = { hidesMessage };
  CustomMessageComponent.prototype.render = function (width: number): string[] {
    const state = this as unknown as MessageState;
    if (!patch.hidesMessage(state.message)) return originalRender.call(this, width);
    const failures = failedDevWorkOutcomeChildren(state.message?.content);
    return failures.length > 0
      ? ["", ...new Text(calmChildFailureNotice(failures), 1, 0).render(width)]
      : [];
  };
  registry[CALM_WORK_MESSAGES_PATCH] = patch;
}
