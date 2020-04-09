<template>
  <div>
    <b-navbar toggleable="lg" type="light" variant="light">
      <b-navbar-brand>
        <button @click="clickOnToggleMenu" class="btn btn-outline-dark" id="menu-toggle">
          {{ toggleMenuName }}
        </button>
      </b-navbar-brand>

      <b-navbar-toggle target="nav-collapse"></b-navbar-toggle>

      <b-collapse id="nav-collapse" is-nav>
        <b-navbar-nav class="ml-auto">
          <b-link class="text-dark" v-bind:to="exitRef">{{ exit }}</b-link>
        </b-navbar-nav>
      </b-collapse>
    </b-navbar>
  </div>
</template>
<script>
export default {
    data() {
        return {
            toggleMenuName: 'Toggle Menu',
            exit: 'Log Out',
            exitRef: 'logout',
        }
    },
    methods: {
        clickOnToggleMenu(){
          this.$emit("set-side-bar-activity")
        }
    }
}    
</script>
