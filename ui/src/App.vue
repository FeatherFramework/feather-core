<script setup>
import api from "./api";
import { ref, onMounted, onUnmounted } from "vue";
import "@/assets/styles/main.css";
import { usePlayerStore } from "@/store/player";
import { useLocaleStore } from '@/store/locale';

const devmode = ref(false);
const visible = ref(false);
const pvp = ref(false)
const store = usePlayerStore();
const locale = useLocaleStore();

onMounted(() => {
  window.addEventListener("message", onMessage);
});

onUnmounted(() => {
  window.removeEventListener("message", onMessage);
});

const onMessage = (event) => {
  switch (event.data.type) {
    case "toggle":
      store.storePlayer(event.data.player, event.data.config);

      locale.storeLocale(event.data.locale);

      pvp.value = event.data.pvp

      visible.value = event.data.visible;
      api
        .post("updatestate", {
          state: visible.value,
        })
        .catch((e) => {
          console.log(e.message);
        });
      break;
    default:
      break;
  }
};

const closeApp = () => {
  visible.value = false;
  api.post("updatestate", {
    state: visible.value,
  })
    .catch((e) => {
      console.log(e.message);
    });
};

const togglePVP = () => {
  pvp.value = !pvp.value
  api.post("togglepvp", {})
    .catch((e) => {
      console.log(e.message);
    });
}
</script>

<template>
  <Transition name="bounce">
    <div id="content" class="centerit text-white mx-auto px-10 pt-12 max-w-sm rounded overflow-hidden aspect-[1/2]"
      v-if="visible || devmode">
      <div class="px-6 main-view">
        <router-view />
      </div>
      <div class="absolute bottom-10 left-0 w-full h-16">
        <img style="width:90%; margin: 0 auto;" src="./assets/hr_bottom.png" />

        <div style="width:90%;" class="grid max-w-lg grid-cols-4 mx-auto font-medium">
          <router-link active-class="active" to="/" class="inline-flex flex-col items-center justify-center px-5 group">
            <svg class="w-8 h-8 mb-2 text-gray-500 group-hover:text-red-400" aria-hidden="true" fill="currentColor"
              xmlns="http://www.w3.org/2000/svg" height="1em"
              viewBox="0 0 640 512"><!--! Font Awesome Free 6.4.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license (Commercial License) Copyright 2023 Fonticons, Inc. -->
              <path
                d="M320 64c14.4 0 22.3-7 30.8-14.4C360.4 41.1 370.7 32 392 32c49.3 0 84.4 152.2 97.9 221.9C447.8 272.1 390.9 288 320 288s-127.8-15.9-169.9-34.1C163.6 184.2 198.7 32 248 32c21.3 0 31.6 9.1 41.2 17.6C297.7 57 305.6 64 320 64zM111.1 270.7c47.2 24.5 117.5 49.3 209 49.3s161.8-24.8 208.9-49.3c24.8-12.9 49.8-28.3 70.1-47.7c7.9-7.9 20.2-9.2 29.6-3.3c9.5 5.9 13.5 17.9 9.9 28.5c-13.5 37.7-38.4 72.3-66.1 100.6C523.7 398.9 443.6 448 320 448s-203.6-49.1-252.5-99.2C39.8 320.4 14.9 285.8 1.4 248.1c-3.6-10.6 .4-22.6 9.9-28.5c9.5-5.9 21.7-4.5 29.6 3.3c20.4 19.4 45.3 34.8 70.1 47.7z" />
            </svg>
          </router-link>
          <router-link active-class="active" to="/settings"
            class="inline-flex flex-col items-center justify-center px-5 group">
            <svg class="w-8 h-8 mb-2 text-gray-500 group-hover:text-red-400" aria-hidden="true"
              xmlns="http://www.w3.org/2000/svg" fill="currentColor" height="1em"
              viewBox="0 0 512 512"><!--! Font Awesome Free 6.4.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license (Commercial License) Copyright 2023 Fonticons, Inc. -->
              <path
                d="M495.9 166.6c3.2 8.7 .5 18.4-6.4 24.6l-43.3 39.4c1.1 8.3 1.7 16.8 1.7 25.4s-.6 17.1-1.7 25.4l43.3 39.4c6.9 6.2 9.6 15.9 6.4 24.6c-4.4 11.9-9.7 23.3-15.8 34.3l-4.7 8.1c-6.6 11-14 21.4-22.1 31.2c-5.9 7.2-15.7 9.6-24.5 6.8l-55.7-17.7c-13.4 10.3-28.2 18.9-44 25.4l-12.5 57.1c-2 9.1-9 16.3-18.2 17.8c-13.8 2.3-28 3.5-42.5 3.5s-28.7-1.2-42.5-3.5c-9.2-1.5-16.2-8.7-18.2-17.8l-12.5-57.1c-15.8-6.5-30.6-15.1-44-25.4L83.1 425.9c-8.8 2.8-18.6 .3-24.5-6.8c-8.1-9.8-15.5-20.2-22.1-31.2l-4.7-8.1c-6.1-11-11.4-22.4-15.8-34.3c-3.2-8.7-.5-18.4 6.4-24.6l43.3-39.4C64.6 273.1 64 264.6 64 256s.6-17.1 1.7-25.4L22.4 191.2c-6.9-6.2-9.6-15.9-6.4-24.6c4.4-11.9 9.7-23.3 15.8-34.3l4.7-8.1c6.6-11 14-21.4 22.1-31.2c5.9-7.2 15.7-9.6 24.5-6.8l55.7 17.7c13.4-10.3 28.2-18.9 44-25.4l12.5-57.1c2-9.1 9-16.3 18.2-17.8C227.3 1.2 241.5 0 256 0s28.7 1.2 42.5 3.5c9.2 1.5 16.2 8.7 18.2 17.8l12.5 57.1c15.8 6.5 30.6 15.1 44 25.4l55.7-17.7c8.8-2.8 18.6-.3 24.5 6.8c8.1 9.8 15.5 20.2 22.1 31.2l4.7 8.1c6.1 11 11.4 22.4 15.8 34.3zM256 336a80 80 0 1 0 0-160 80 80 0 1 0 0 160z" />
            </svg>
          </router-link>

          <button type="button" class="inline-flex flex-col items-center justify-center px-5 group" @click="togglePVP">
            <svg class="w-8 h-8 mb-2 text-gray-500 group-hover:text-red-400" aria-hidden="true"
              xmlns="http://www.w3.org/2000/svg" fill="currentColor" height="1em"
              viewBox="0 0 512 512"><!--! Font Awesome Free 6.4.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license (Commercial License) Copyright 2023 Fonticons, Inc. -->
              <path
                d="M416 398.9c58.5-41.1 96-104.1 96-174.9C512 100.3 397.4 0 256 0S0 100.3 0 224c0 70.7 37.5 133.8 96 174.9c0 .4 0 .7 0 1.1v64c0 26.5 21.5 48 48 48h48V464c0-8.8 7.2-16 16-16s16 7.2 16 16v48h64V464c0-8.8 7.2-16 16-16s16 7.2 16 16v48h48c26.5 0 48-21.5 48-48V400c0-.4 0-.7 0-1.1zM96 256a64 64 0 1 1 128 0A64 64 0 1 1 96 256zm256-64a64 64 0 1 1 0 128 64 64 0 1 1 0-128z" />
            </svg>
          </button>
          <div class="inline-flex flex-col items-center justify-center px-5 group">
            <div class="w-10 h-5 mb-2 text-black bg-gray-500 text-center rounded-sm">
              {{ store.id }}
            </div>
          </div>
        </div>
      </div>

      <div class="absolute left-6 top-4 text-2xl text-white cursor-pointer  hover:text-red-400 " @click="closeApp">
        &times;
      </div>
    </div>
  </Transition>
</template>

<style>
@font-face {
  font-family: rdrlino;
  src: url(assets/fonts/rdrlino-regular.ttf);
}

@font-face {
  font-family: chinarocks;
  src: url(assets/fonts/chinese-rocks.ttf);
}

::-webkit-scrollbar {
  width: 6px;
}

/* Track */
::-webkit-scrollbar-track {
  background: #f1f1f1;
}

/* Handle */
::-webkit-scrollbar-thumb {
  background: #888;
}

/* Handle on hover */
::-webkit-scrollbar-thumb:hover {
  background: #555;
}

#app {
  font-family: rdrlino;
  touch-action: manipulation;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  color: #fff;
  overflow: hidden;
}

body {
  overflow: hidden;
}

.chinarocks {
  font-family: chinarocks !important;
}

.centerit {
  position: absolute;
  right: 0;
  top: 50%;

  transform: translateY(-50%);
}


#content {
  width: 60vh;
  height: 80vh;

  max-height: 600px;
  z-index: 99999;

  position: absolute;
  right: 0;
  top: 50%;


  transform: translateY(-50%);
}


#content::before {
  content: "";
  position: absolute;
  width: 98%;
  height: 100%;
  top: 0px;
  bottom: 0;
  right: 0;
  left: 0px;
  z-index: -1;
  background-size: cover;
  background-image: url(assets/inkroller.png);
  background-repeat: no-repeat;
  transform: rotate(180deg);
}

.main-view {
  height: 84%;
  overflow-y: auto;
}

.active svg {
  color: indianred;
  cursor: pointer;
}


.bounce-enter-active {
  animation: bounce-in 0.5s;
}

.bounce-leave-active {
  animation: bounce-in 0.5s reverse;
}

@keyframes bounce-in {
  0% {
    transform: translate(40vw, -50%);
  }

  50% {
    transform: translateX(20vw, -50%);
  }

  100% {
    transform: translateX(0, -50%);
  }
}
</style>
