<template>
  <div class="d-flex" id="app">
    <SideBar v-show="isActive" @send-device-name="setDeviceName"/>
    <div id="page-content-app">
      <NavBar @set-side-bar-activity="setSideBarActivity"/>
      <PageContent ref="pageContentComponent"/>
    </div>
  </div>
</template>
<script>
  import SideBar from './components/SideBar.vue'; 
  import PageContent from './components/PageContent.vue'
  import NavBar from './components/NavBar.vue';  
  export default {
    name: 'navbar',
    data(){
      return {
        isActive: true
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
      }
    }
  }
</script>
<style>
body {
  overflow-x: hidden;
}

@media (min-width: 768px) {
  #app.toggled {
    margin-left: -15rem;
  }
}
</style>