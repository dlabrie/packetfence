import { computed, toRefs } from '@vue/composition-api'

export const useItemTitle = (props) => {
  const {
    id
  } = toRefs(props)
  return computed(() => id.value.toUpperCase())
}

export { useStore } from '../_store'
