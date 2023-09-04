import { NodeChartModel } from '@/components/NodeChart/model'
import {NodeChartView} from '@/components/NodeChart/view'

export default function Home() {
  const model = new NodeChartModel()
  return (
    <div className="container-fluid">
      <div className='row'>
        <div className='col-6'>
          <NodeChartView model={model} />
        </div>
        <div className='col-6'>
          <NodeChartView model={model} />
        </div>
      </div>
    </div>
  )
}
