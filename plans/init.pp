# This is the structure of a simple plan. To learn more about writing
# Puppet plans, see the documentation: http://pup.pt/bolt-puppet-plans

# The summary sets the description of the plan that will appear
# in 'bolt plan show' output. Bolt uses puppet-strings to parse the
# summary and parameters from the plan.
# @summary A plan created with bolt plan new.
# @param targets The targets to run on.
plan bootstrap_ospuppet (
  TargetSpec $targets,
  Stdlib::Absolutepath $tmp_dir = '/tmp/modules',
) {
  # Install Puppet agent on target(s) so that Puppet code can run
  $targets.apply_prep
  run_command("rm -rf ${tmp_dir}", $targets)

  out::message('# Install puppet/r10k module')
  run_command(@("CMD"/L), $targets)
    /opt/puppetlabs/bin/puppet module install \
    --environment production --modulepath=${tmp_dir} \
    puppet/r10k
    | CMD

  out::message('# Configure r10k')
  run_command(@("CMD"/L), $targets)
    /opt/puppetlabs/bin/puppet apply \
    --environment production --modulepath=/tmp/modules \
    -e "class { 'r10k': remote => 'https://github.com/ndelic0/ospuppet-control-repo.git' }"
    | CMD
  out::message('# Run the deploy command')
  run_command("r10k deploy environment production -pv || exit 1", $targets, '_run_as' => 'root')

  out::message('# Run the puppet apply command')
  run_command(@("CMD"/L), $targets)
    /opt/puppetlabs/bin/puppet apply \
    --environment production \
    -e "include profile::puppet::puppetserver"
    | CMD

}
