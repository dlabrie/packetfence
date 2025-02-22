import store from '@/store'
import BasesStoreModule from '../../bases/_store'

const TheTabs = () => import(/* webpackChunkName: "Configuration" */ '../../_components/TheTabsRadius')

export const beforeEnter = (to, from, next = () => {}) => {
  if (!store.state.$_bases)
    store.registerModule('$_bases', BasesStoreModule)
  next()
}

export default [
  {
    path: 'radius',
    name: 'radiusGeneral',
    component: TheTabs,
    props: () => ({ tab: 'radiusGeneral' }),
    beforeEnter
  }
]
