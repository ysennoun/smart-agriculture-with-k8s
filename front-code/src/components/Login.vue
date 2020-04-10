<template>
  <div id="login" class="container h-100 d-flex justify-content-center">
    <div class="jumbotron my-auto">
    <b-card>
        <h5 class="text-center">
            <img v-bind:src="logo" width="25" height="25" style="vertical-align: top;" alt="">
            <span style="vertical-align: middle;">&nbsp;Smart Agriculture</span>
            <hr>
        </h5>
        
        <b-form @submit="onSubmit">
        <b-form-group>
            <b-form-input
            id="text-login"
            v-model="form.login"
            required
            placeholder="Enter login"
            ></b-form-input>
        </b-form-group>
        <b-form-group>
            <b-input 
                type="password" 
                id="text-password" 
                v-model="form.password"
                placeholder="Enter password"
                required
                aria-describedby="password-help-block"
            ></b-input>
        </b-form-group>
        <b-button id="button-register" block type="submit">Register</b-button>
        </b-form>
    </b-card>   
    </div>
  </div>
</template>

<script>
  export default {
    data() {
      return {
        logo: require('../assets/images/plant.png'),
        form: {
          login: null,
          password: null
        }
      }
    },
    methods: {
      onSubmit(evt) {
        evt.preventDefault()
        this.$store.dispatch('setCredentials', this.form).then(() => {
          this.$router.push({ path: 'content'});
        });
      }
    }
  }
</script>
<style>
html, body {
    height: 100%;
}

#button-register {
    background-color: #74992e;
    border-color: white;
    height: 100%;
}
</style>
