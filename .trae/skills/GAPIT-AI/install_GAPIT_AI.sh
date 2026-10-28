#!/bin/bash

# GAPIT专家技能安装脚本
# 版本：2.0.0
# 更新日期：2026-07-13
# 说明：
# - 当前项目内的 .trae/skills/GAPIT-AI 是主理人维护副本
# - 本脚本主要用于把该副本复制到 ~/.trae/skills/ 供其他工作区或其他账户使用
# - 如果已经在 GAPIT-Agent 项目工作区中使用 Trae，通常不需要额外安装

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Trae IDE安装
check_trae_installation() {
    log_info "检查Trae IDE安装..."
    
    if command -v trae &> /dev/null; then
        log_success "Trae IDE已安装"
        TRAE_VERSION=$(trae --version 2>/dev/null || echo "未知版本")
        log_info "Trae版本: $TRAE_VERSION"
    else
        log_error "未找到Trae IDE，请先安装Trae IDE"
        exit 1
    fi
}

# 检查技能目录
check_skill_directory() {
    log_info "检查技能目录..."
    
    local TRAE_HOME="$HOME/.trae"
    local SKILLS_DIR="$TRAE_HOME/skills"
    
    if [ ! -d "$TRAE_HOME" ]; then
        log_warning "Trae主目录不存在，创建中..."
        mkdir -p "$TRAE_HOME"
    fi
    
    if [ ! -d "$SKILLS_DIR" ]; then
        log_warning "技能目录不存在，创建中..."
        mkdir -p "$SKILLS_DIR"
    fi
    
    log_success "技能目录检查完成"
}

# 安装技能
install_skill() {
    log_info "开始安装GAPIT专家技能..."
    
    local SKILL_NAME="GAPIT-AI"
    local SKILL_SOURCE_DIR="$(dirname "$0")"
    local SKILL_TARGET_DIR="$HOME/.trae/skills/$SKILL_NAME"
    
    log_info "源目录: $SKILL_SOURCE_DIR"
    log_info "目标目录: $SKILL_TARGET_DIR"
    
    # 备份原有技能（如果存在）
    if [ -d "$SKILL_TARGET_DIR" ]; then
        local BACKUP_DIR="${SKILL_TARGET_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
        log_warning "发现已存在的技能，备份到: $BACKUP_DIR"
        cp -r "$SKILL_TARGET_DIR" "$BACKUP_DIR"
        rm -rf "$SKILL_TARGET_DIR"
    fi
    
    # 复制技能文件
    log_info "复制技能文件..."
    cp -r "$SKILL_SOURCE_DIR" "$SKILL_TARGET_DIR"
    
    # 设置文件权限
    chmod -R 755 "$SKILL_TARGET_DIR"
    
    log_success "技能文件复制完成"
}

# 验证安装
verify_installation() {
    log_info "验证技能安装..."
    
    local SKILL_NAME="GAPIT-AI"
    local SKILL_DIR="$HOME/.trae/skills/$SKILL_NAME"
    
    # 检查目录是否存在
    if [ ! -d "$SKILL_DIR" ]; then
        log_error "技能目录不存在: $SKILL_DIR"
        return 1
    fi
    
    # 检查必要文件
    local REQUIRED_FILES=("SKILL.md" "INSTALL.md")
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$SKILL_DIR/$file" ]; then
            log_error "缺少必要文件: $file"
            return 1
        fi
    done
    
    # 检查技能是否在列表中
    if trae skill list 2>/dev/null | grep -q "$SKILL_NAME"; then
        log_success "技能已成功注册"
    else
        log_warning "技能未在列表中显示，可能需要重启Trae IDE"
    fi
    
    log_success "安装验证完成"
}

# 显示安装摘要
show_summary() {
    echo ""
    echo "========================================="
    echo "        GAPIT专家技能安装完成"
    echo "========================================="
    echo ""
    echo "📁 技能位置: $HOME/.trae/skills/GAPIT-AI/"
    echo "📄 文档文件:"
    echo "   - SKILL.md    : 技能功能说明"
    echo "   - INSTALL.md  : 安装和使用指南"
    echo ""
    echo "🚀 使用方法:"
    echo "   1. 如果你已在 GAPIT-Agent 项目工作区中，直接重启或刷新 Trae"
    echo "   2. 在对话中直接提问 GAPIT 问题，或点名 GAPIT-AI"
    echo "   3. 若复制到 ~/.trae/skills/，则可在其他工作区继续调用"
    echo ""
    echo "💡 示例问题:"
    echo "   - 请调用 GAPIT-AI，解释 GAPIT 安装失败怎么办"
    echo "   - 请调用 GAPIT-AI，我有1000个样本该选什么模型"
    echo "   - 请调用 GAPIT-AI，解释曼哈顿图和 QQ 图"
    echo ""
    echo "📝 反馈渠道:"
    echo "   - GAPIT交流群"
    echo "   - GitHub Issues"
    echo ""
    echo "⚠️  注意事项:"
    echo "   - 当前项目副本是主理人维护源"
    echo "   - 对外版本建议从当前副本重新打包发布"
    echo "   - 遇到问题请先回收反馈再升级主技能"
    echo ""
    echo "========================================="
    echo ""
}

# 主函数
main() {
    echo ""
    echo "========================================="
    echo "    GAPIT专家技能安装程序 v2.0.0"
    echo "========================================="
    echo ""
    log_info "提示：如果你已经打开 GAPIT-Agent 项目工作区，"
    log_info "项目内的 .trae/skills/GAPIT-AI 已可作为 workspace skill 直接调用。"
    log_info "本脚本主要用于向 ~/.trae/skills/ 安装一个可分发副本。"
    echo ""
    
    # 检查Trae IDE
    check_trae_installation
    
    # 检查技能目录
    check_skill_directory
    
    # 安装技能
    install_skill
    
    # 验证安装
    if verify_installation; then
        log_success "技能安装成功！"
    else
        log_error "技能安装验证失败"
        exit 1
    fi
    
    # 显示摘要
    show_summary
    
    log_info "安装完成！请重启Trae IDE后使用。"
    echo ""
}

# 执行主函数
main "$@"
