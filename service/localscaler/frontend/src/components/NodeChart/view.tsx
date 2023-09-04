import { NodeChartModel } from "./model"

const COLOR_TABLE = {
    'CPU':'#fb5607',
    'MEM':'#ff006e',
    'STORAGE':'#8338ec',
    'GPU':'#3a86ff'
}

export function NodeChartView({model}:{model:NodeChartModel}) {
    return <div>
        <h3>{model.name}</h3>
        <BarChart 
            label={'CPU'} 
            color={COLOR_TABLE['CPU']} 
            desc={model.cpu.temperature+'C'}
            value={model.cpu.rate} />
        <BarChart 
            label={'Memory'} 
            color={COLOR_TABLE['MEM']}
            desc={model.memory.value +'/'+model.memory.total+'G'}
            value={model.memory.rate} />
        <BarChart 
            label={'Storage'} 
            color={COLOR_TABLE['STORAGE']} 
            desc={model.storage.value + '/' + model.storage.total + 'G'}
            value={model.storage.rate}
            />
        {model.gpu ? <BarChart 
            label={'GPU'} 
            color={COLOR_TABLE['GPU']} 
            desc={model.gpu?.temperature + '°C'}
            value={30} /> : <div style={{height:24}}></div>}
    </div>
}

function BarChart({
    label,
    desc,
    color, 
    value
}:{
    label:string
    desc:string
    color:string 
    value:number
}) {
    return <div className="d-flex align-items-center">
        <div style={{width:80}}>
            {label}
        </div>
        <div style={{
            width:'100%',
            background:'lightgray',
            borderBottom:'solid 1px white',
            borderRadius:4,
        }}>
            <div className="d-flex justify-content-between ps-2 pe-2" style={{
                height:"100%",
                width:value+'%',
                background:color,
                color:"white",
                fontSize:12,
                borderRadius:4
            }}>
                <div>{desc}</div>
                <div>{value}%</div>
            </div>
        </div>
    </div>
}