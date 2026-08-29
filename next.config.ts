import type { NextConfig } from "next";
import createNextIntlPlugin from "next-intl/plugin";

const nextConfig: NextConfig = {
  // CLAUDE.md is a hand-authored project document (see CLAUDE.md itself,
  // PRODUCT.md, DESIGN.md, ARCHITECTURE.md) -- don't let `next dev` append
  // its generated agent-rules block to it on every run.
  agentRules: false,
};

const withNextIntl = createNextIntlPlugin("./src/i18n/request.ts");

export default withNextIntl(nextConfig);
