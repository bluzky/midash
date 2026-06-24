import { get } from "../api.js";
import {
  fmtRate,
  fmtAnnualized,
  fmtOI,
  fmtChange,
  fmtPrice,
  fmtCountdown,
} from "../fmt.js";

function rateVariant(r) {
  if (r == null) return "muted";
  if (r > 0.00004) return "success";
  if (r < -0.00004) return "error";
  return "default";
}

function changeVariant(v) {
  if (v == null) return "muted";
  if (v > 0) return "success";
  if (v < 0) return "error";
  return "muted";
}

export function cryptoFunding({ symbols = ["ETHUSDT", "BTCUSDT"] } = {}) {
  const qs = symbols.map((s) => `symbols[]=${s}`).join("&");
  return {
    key: `/api/crypto/funding?${qs}#table`,
    staleTime: 15,
    async fetch() {
      const res = await get(`/api/crypto/funding?${qs}`);
      const rows = res.data
        .filter((item) => !item.error)
        .map((item) => ({
          symbol: {
            text: item.symbol.replace("USDT", "").replace("USDC", ""),
            variant: "default",
          },
          rate: {
            text: fmtRate(item.last_funding_rate),
            variant: rateVariant(item.last_funding_rate),
          },
          annualized: {
            text: fmtAnnualized(item.last_funding_rate),
            variant: rateVariant(item.last_funding_rate),
          },
          oi: { text: fmtOI(item.open_interest), variant: "default" },
          oi24h: {
            text: fmtChange(item.oi_change_24h),
            variant: changeVariant(item.oi_change_24h),
          },
          price: { text: fmtPrice(item.mark_price), variant: "default" },
          next: {
            text: fmtCountdown(item.next_funding_time),
            variant: "muted",
          },
        }));
      return {
        columns: [
          { key: "symbol", label: "symbol", width: "64px" },
          { key: "rate", label: "rate (8h)", align: "right" },
          { key: "annualized", label: "24h ann", align: "right" },
          { key: "oi", label: "OI", align: "right" },
          { key: "oi24h", label: "OI 24h", align: "right" },
          { key: "price", label: "price", align: "right" },
          { key: "next", label: "next", align: "right", width: "80px" },
        ],
        rows,
      };
    },
  };
}

export function cryptoPriceSnapshot({ symbols = ["ETHUSDT", "BTCUSDT"] } = {}) {
  const qs = symbols.map((s) => `symbols[]=${s}`).join("&");
  return {
    key: `/api/crypto/funding?${qs}#snapshot`,
    staleTime: 15,
    async fetch() {
      const res = await get(`/api/crypto/funding?${qs}`);
      return {
        pairs: res.data
          .filter((item) => !item.error)
          .map((item) => ({
            key: item.symbol.replace("USDT", "").replace("USDC", ""),
            value: fmtPrice(item.mark_price),
            meta: fmtChange(item.oi_change_24h),
          })),
      };
    },
  };
}
