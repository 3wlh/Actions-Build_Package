module("luci.model.napcat.docker", package.seeall)

local json = require("luci.jsonc")
local sys = require("luci.sys")

-- 检查Docker是否可用
function is_docker_available()
    return sys.call("which docker >/dev/null 2>&1") == 0
end

-- 获取容器状态
function get_container_status(container_name)
    if not is_docker_available() then
        return {status = "error", message = "Docker not available"}
    end
    
    -- 检查容器是否存在
    local cmd = string.format("docker ps -aq -f name=%s", container_name)
    local container_id = sys.exec(cmd)
    
    if container_id == "" then
        return {status = "not_exists", running = false}
    end
    
    -- 检查容器是否运行
    cmd = string.format("docker ps -q -f name=%s", container_name)
    local running_id = sys.exec(cmd)
    
    if running_id == "" then
        return {status = "stopped", running = false, id = container_id:gsub("\n", "")}
    else
        -- 获取容器详细信息
        cmd = string.format("docker inspect %s", container_id:gsub("\n", ""))
        local inspect_output = sys.exec(cmd)
        local inspect_data = json.parse(inspect_output)
        
        if inspect_data and inspect_data[1] then
            local data = inspect_data[1]
            return {
                status = "running",
                running = true,
                id = data.Id,
                name = data.Name:gsub("^/", ""),
                image = data.Config.Image,
                created = data.Created,
                ports = data.NetworkSettings.Ports,
                ip = data.NetworkSettings.IPAddress or "N/A"
            }
        end
    end
    
    return {status = "unknown", running = false}
end

-- 获取容器资源使用情况
function get_container_stats(container_name)
    if not is_docker_available() then
        return {error = "Docker not available"}
    end
    
    local cmd = string.format("docker stats --no-stream --format '{{json .}}' %s", container_name)
    local output = sys.exec(cmd)
    
    if output and output ~= "" then
        -- 清理输出，确保是有效的JSON
        output = output:gsub("'", '"')
        output = output:gsub("%%", "")
        
        local stats = json.parse(output)
        if stats then
            return {
                cpu = stats.CPUPerc or "0.0%",
                memory = stats.MemPerc or "0.0%",
                memory_usage = stats.MemUsage or "0 B / 0 B",
                network = stats.NetIO or "0 B / 0 B",
                block = stats.BlockIO or "0 B / 0 B",
                pids = stats.PIDs or "0"
            }
        end
    end
    
    return {cpu = "0.0%", memory = "0.0%", memory_usage = "0 B / 0 B", network = "0 B / 0 B", block = "0 B / 0 B", pids = "0"}
end

-- 启动容器
function start_container(config)
    if not is_docker_available() then
        return false, "Docker not available"
    end
    
    -- 检查容器是否已存在
    local status = get_container_status(config.container_name)
    
    if status.running then
        return true, "容器已经在运行"
    end
    
    -- 构建docker run命令
    local cmd = string.format("docker run -d --name %s", config.container_name)
    
    -- 添加端口映射
    if config.ports then
        for _, port_map in ipairs(config.ports) do
            cmd = cmd .. string.format(" -p %s", port_map)
        end
    end
    
    -- 添加数据卷
    if config.data_dir then
        cmd = cmd .. string.format(" -v %s:/app/data", config.data_dir)
    end
    
    -- 添加网络模式
    if config.network_mode then
        cmd = cmd .. string.format(" --network %s", config.network_mode)
    end
    
    -- 添加环境变量
    if config.env then
        for _, env in ipairs(config.env) do
            cmd = cmd .. string.format(" -e %s", env)
        end
    end
    
    -- 添加额外参数
    if config.extra_args then
        cmd = cmd .. " " .. config.extra_args
    end
    
    -- 添加镜像名称
    cmd = cmd .. " " .. config.image
    
    -- 执行命令
    local result = sys.exec(cmd)
    
    if result and result ~= "" then
        return true, "容器启动成功"
    else
        return false, "容器启动失败，请检查配置"
    end
end

-- 停止容器
function stop_container(container_name)
    if not is_docker_available() then
        return false, "Docker not available"
    end
    
    local cmd = string.format("docker stop %s", container_name)
    local result = sys.exec(cmd)
    
    if result and result:find(container_name) then
        return true, "容器已停止"
    else
        return false, "容器停止失败"
    end
end

-- 重启容器
function restart_container(container_name)
    if not is_docker_available() then
        return false, "Docker not available"
    end
    
    local cmd = string.format("docker restart %s", container_name)
    local result = sys.exec(cmd)
    
    if result and result:find(container_name) then
        return true, "容器已重启"
    else
        return false, "容器重启失败"
    end
end

-- 拉取镜像
function pull_image(image_name)
    if not is_docker_available() then
        return false, "Docker not available"
    end
    
    local cmd = string.format("docker pull %s", image_name)
    local result = sys.exec(cmd)
    
    if result and result:find("Downloaded newer image") then
        return true, "镜像更新成功"
    elseif result and result:find("Image is up to date") then
        return true, "镜像已是最新版本"
    else
        return false, "镜像拉取失败"
    end
end