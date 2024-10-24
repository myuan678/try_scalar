import matplotlib.pyplot as plt

def plot_curves(x_values, y_values_list, labels=None, x_label=None, y_labels=None, filename="plot.png"):
    # plt.figure(figsize=figsize)
    for i, y_values in enumerate(y_values_list):
        label = labels[i] if labels else f"Curve {i+1}"
        plt.plot(x_values, y_values, marker='o',label=label)
        for j, value in enumerate(y_values):
            plt.text(x_values[j], value, f'{value:.3g}', fontsize=9, ha='left', va='bottom')
  
    
    plt.xlabel(x_label if x_label else "")
    plt.ylabel(", ".join(y_labels) if y_labels else "")
    plt.title("MEXT - DELAY")
    plt.xticks(rotation=45)
    plt.legend()
    # plt.grid(True)
    plt.tight_layout()
    # 保存图片到文件
    plt.savefig(filename)
    
    # 显示图片
    plt.show()

# 示例数据
# x_values = ["1 dispatch", "4 dispatch", "Rename", "dev-lsu", "cancel", "BP", "dev-OOO"]
x_values = ["delay 0", "delay 1", "delay 2", "delay 3" , "delay 4" ,"delay 5"]
y_values_list = [
    [          1.702287,          1.691412,          1.670237,          1.649392,          1.629269,          1.609613],
    [          3.641920,          3.618626,          3.573324,          3.528728,          3.485678,          3.443625]
]
labels = ["Dhry IPC", "Dhry DMIPS/Mhz"]
# x_label = ""
# y_labels = "IPC"

plot_curves(x_values, y_values_list, labels, filename="mext.jpg")
