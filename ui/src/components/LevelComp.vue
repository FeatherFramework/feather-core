<script setup>
import { computed } from 'vue'

const props = defineProps({
    current: {
        required: true
    },
    goal: {
        required: true
    },
    level: {
        required: true
    }
})

const barlength = computed(() => {
    return (Number(props.current) / Number(props.goal)) * 100
})


</script>

<template>
    <div class="relative py-10">
        <div class="w-full bg-gray-200 rounded-full h-2.5">
            <div class="bg-red-400 h-2.5 rounded-full" :style="`width: ${barlength}%`"></div>
        </div>
        <div class="flex justify-between mb-1">
            <span class="text-xl font-medium chinarocks">{{ props.current }}</span>
            <span class="text-xl font-medium chinarocks">{{ props.goal }}</span>
        </div>
        <div class="level">
            <div class="w-16 h-16 relative flex items-center justify-center">
                <div class="absolute z-9999 text-black">
                    {{ props.level }}
                </div>
                <img src="../assets/icons/shield.png" />
            </div>
        </div>
    </div>
</template>
<style scoped>
    .level {
        position: absolute;
        top: 28%;
        left: 50%;
        transform: translate(-50%, -28%);
    }
</style>
