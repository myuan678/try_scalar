import re
import os
import pandas as pd
from tabulate import tabulate

def parse_log_file(file_path):
    with open(file_path, 'r') as file:
        content = file.read()
        
        # Extract runs_times and sim_times
        runs_sim_pattern = re.search(r'Execution starts, (\d+) runs through Dhrystone, (\d+) sim calculate.', content)
        if runs_sim_pattern:
            runs_times = int(runs_sim_pattern.group(1))
            sim_times = int(runs_sim_pattern.group(2))
        else:
            runs_times, sim_times = None, None
        
        # Extract IPC
        ipc_pattern = re.search(r'IPC:\s+(\d+\.\d+)', content)
        if ipc_pattern:
            ipc = float(ipc_pattern.group(1))
        else:
            ipc = None
        
        # Extract DMIPS/MHz
        dmips_pattern = re.search(r'DMIPS/MHz:\s+(\d+\.\d+)', content)
        if dmips_pattern:
            dmips = float(dmips_pattern.group(1))
        else:
            dmips = None
        
        # Extract MPKI
        mpki_pattern = re.search(r'Total\s+\d+\s+times cancel\.MPKI\s+(\d+\.\d+)', content)
        if mpki_pattern:
            mpki = float(mpki_pattern.group(1))
        else:
            mpki = None
        
        return runs_times, sim_times, ipc, dmips, mpki

def main():
    log_dir = os.getenv('TOY_SCALAR_PATH') + '/benchmark_output/'
    log_in_dir = os.getenv('TOY_SCALAR_PATH') + '/benchmark_output/dhry/'
    log_files = [f for f in os.listdir(log_in_dir) if re.match(r'f\d+_\d+_\d+_\d+\.log', f)]
    
    data = []
    for log_file in log_files:
        file_path = os.path.join(log_in_dir, log_file)
        runs_times, sim_times, ipc, dmips, mpki = parse_log_file(file_path)
        data.append([runs_times, sim_times, ipc, dmips, mpki, log_file])
    
    # Create a DataFrame
    df = pd.DataFrame(data, columns=['Runs Times', 'Sim Times', 'IPC', 'DMIPS/MHz', 'MPKI', 'Filename'])
    
    # Drop duplicate rows based on 'Runs Times' and 'Sim Times'
    df = df.drop_duplicates(subset=['Runs Times', 'Sim Times'])
    
    # Sort the DataFrame
    df = df.sort_values(by=['Runs Times', 'Sim Times'])
    
    # Fill NaN values with 0 before converting to integers
    df['Runs Times'] = df['Runs Times'].fillna(0).astype(int)
    df['Sim Times'] = df['Sim Times'].fillna(0).astype(int)
    
    # Save to CSV
    csv_output_path = os.path.join(log_dir, 'dhry_summary.csv')
    df.to_csv(csv_output_path, index=False)
    
    # Save to log file
    log_output_path = os.path.join(log_dir, 'dhry_summary.log')
    with open(log_output_path, 'w') as log_file:
        log_file.write(tabulate(df, headers='keys', tablefmt='grid', showindex=False))
    
    # Print to console
    print(tabulate(df, headers='keys', tablefmt='grid', showindex=False))

if __name__ == '__main__':
    main()
