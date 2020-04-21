import { expect } from "chai";
import SideBar from "@/components/SideBar.vue";

describe("SideBar.vue", () => {
    it('return data par default', () => {
      const defaultData = SideBar.data()
      expect(defaultData.title).to.equal('Smart Agriculture')
    })
});
