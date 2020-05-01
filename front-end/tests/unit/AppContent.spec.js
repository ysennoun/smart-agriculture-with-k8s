import { expect } from "chai";
import AppContent from "@/components/AppContent.vue";

describe("AppContent.vue", () => {
    it('return data par default', () => {
      const defaultData = AppContent.data()
      expect(defaultData.isActive).to.equal(true)
    })
});
