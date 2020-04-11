import Vue from "vue";
import Vuex from "vuex";

Vue.use(Vuex);

export default new Vuex.Store({
  state: {
    credentials: {
        login: null,
        password: null
    },
    isAuthenticationFailed: false 
  },
  getters: {
    getCredentials: state => state.credentials,
    areCredentialsSet: state => {
        if (state.credentials.login != null && state.credentials.password != null)
            return true;
        return false;
    },
    isAuthenticationFailed: state => state.isAuthenticationFailed
  },
  mutations: {
    setCredentials(state, credentials) {
        console.log("1");
        console.log(credentials);
        state.credentials = credentials
    },
    setAuthenticationFailed(state, status) {
      state.isAuthenticationFailed = status
    }
  },
  actions: {
    setCredentials(context, credentials) {
        context.commit('setCredentials', credentials)
    },
    setAuthenticationFailed(context, status) {
      context.commit('setAuthenticationFailed', status)
    } 
  },
  modules: {}
});
