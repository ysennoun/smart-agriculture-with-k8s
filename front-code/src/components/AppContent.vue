<template>
  <div class="d-flex" id="app-content">
    <SideBar v-show="isActive" @send-device-name="setDeviceName"/>
    <div id="page-content-app">
      <NavBar @set-side-bar-activity="setSideBarActivity"/>
      <PageContent ref="pageContentComponent"/>
    </div>
  </div>
</template>
<script>
  import SideBar from './SideBar.vue'; 
  import PageContent from './PageContent.vue'
  import NavBar from './NavBar.vue';  
  export default {
    name: 'navbar',
    data(){
      return {
        isActive: true,
      }
    },
    components: {
      SideBar,
      NavBar,
      PageContent
    },
    methods: {
      setDeviceName(device){
        this.$refs.pageContentComponent.setValue(device);
      },
      setSideBarActivity(){
        this.isActive = !this.isActive
      },
      checkCredentials() {
        if(this.$store.getters.areCredentialsSet == false){
          console.log("No credentials return to login page")
          this.$router.push({ path: 'login'})
        }
      }
    },
    mounted() {
      this.checkCredentials()
    }
  }
</script>
<style>
body {
  overflow-x: hidden;
}

@media (min-width: 768px) {
  #app-content.toggled {
    margin-left: -15rem;
  }
}
</style>