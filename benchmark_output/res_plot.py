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
    plt.title("Benchmark")
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
x_values = ["1 dispatch", "4 dispatch + Rename", "dev-lsu", "cancel+not token" , "BP" ,"dev-ooo"]
y_values_list = [
    [          0.883625,          1.034789,          1.085124,          1.001123,          1.544605,          1.702287],
    [          1.879009,          2.200046,          2.307061,          2.129661,          3.304547,          3.641920],
    [       2.684157352,       3.064727348,       3.065582309,       2.773868934,       3.862525010,       4.164209783]
]
labels = ["Dhry IPC", "Dhry DMIPS/Mhz","Core Mark MIPS/MHz"]
# x_label = ""
# y_labels = "IPC"

plot_curves(x_values, y_values_list, labels, filename="benchmark.jpg")
