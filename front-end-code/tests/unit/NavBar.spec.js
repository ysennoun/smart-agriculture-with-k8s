import { expect } from "chai";
import NavBar from "@/components/NavBar.vue";

describe("NavBar.vue", () => {
    it('return data par default', () => {
      const defaultData = NavBar.data()
      expect(defaultData.toggleMenuName).to.equal('Toggle Menu')
      expect(defaultData.exit).to.equal('Log Out')
    })
});
